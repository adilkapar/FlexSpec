sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/ui/core/mvc/OverrideExecution",
    "sap/m/MessageBox",
    "sap/m/MessageToast"
], function (ControllerExtension, OverrideExecution, MessageBox, MessageToast) {
    "use strict";

    return ControllerExtension.extend("flexspec.ext.UploadExtension", {

        metadata: {
            methods: {
                onDownloadTemplate: { "public": true, "final": false },
                onUploadExcel: { "public": true, "final": false }
            }
        },

        /**
         * Download Template button handler
         * Reads all attribute IDs from FlexAttributes entity set
         * and generates a 2-sheet Excel template
         */
        onDownloadTemplate: function () {
            var oModel = this.base.getModel();
            var oListBinding = oModel.bindList("/FlexAttributes");

            oListBinding.requestContexts(0, 9999).then(function (aContexts) {
                var aAttributes = aContexts.map(function (oCtx) {
                    return {
                        AttributeId: oCtx.getProperty("AttributeId"),
                        Description: oCtx.getProperty("Description")
                    };
                });

                if (aAttributes.length === 0) {
                    MessageBox.warning("No attributes found in configuration table. Please maintain ZSPEC_FLEX_CMAP first.");
                    return;
                }

                // Build Excel workbook with 2 sheets
                var oWorkbook = XLSX.utils.book_new();

                // Sheet 1: Header
                var aHeaderData = [
                    ["ROW_ID", "DESCRIPTION"],
                    ["1", "(Enter spec description here)"],
                    ["2", "(Enter spec description here)"]
                ];
                var wsHeader = XLSX.utils.aoa_to_sheet(aHeaderData);
                XLSX.utils.book_append_sheet(oWorkbook, wsHeader, "Header");

                // Sheet 2: Items — pre-filled with all attribute IDs for ROW 1 and ROW 2
                var aItemData = [["ROW_ID", "ATTRIBUTE_ID", "ATTRIBUTE_VALUE"]];

                // Add all attributes for ROW_ID = 1
                aAttributes.forEach(function (attr) {
                    aItemData.push(["1", attr.AttributeId, ""]);
                });

                // Add all attributes for ROW_ID = 2
                aAttributes.forEach(function (attr) {
                    aItemData.push(["2", attr.AttributeId, ""]);
                });

                var wsItems = XLSX.utils.aoa_to_sheet(aItemData);
                XLSX.utils.book_append_sheet(oWorkbook, wsItems, "Items");

                // Trigger download
                XLSX.writeFile(oWorkbook, "FlexSpec_Upload_Template.xlsx");

                MessageToast.show("Template downloaded successfully.");

            }).catch(function (oError) {
                MessageBox.error("Failed to read attributes: " + oError.message);
            });
        },

        /**
         * Upload from Excel button handler
         * Opens native file picker, reads file, calls UploadExcel action
         */
        onUploadExcel: function () {
            var that = this;

            // Create a hidden file input element
            var oFileInput = document.createElement("input");
            oFileInput.type = "file";
            oFileInput.accept = ".xlsx,.xls";
            oFileInput.style.display = "none";
            document.body.appendChild(oFileInput);

            oFileInput.addEventListener("change", function (oEvent) {
                var oFile = oEvent.target.files[0];
                if (!oFile) {
                    document.body.removeChild(oFileInput);
                    return;
                }

                var sFileName = oFile.name;

                var oReader = new FileReader();
                oReader.onload = function (e) {
                    var sBase64 = e.target.result.split(",")[1]; // Remove data:...;base64, prefix

                    // Call the UploadExcel action
                    var oModel = that.base.getModel();
                    var oActionBinding = oModel.bindContext("/SpecFlex/com.sap.gateway.srvd.zsd_spec_flex.v0001.UploadExcel(...)");

                    oActionBinding.setParameter("file_content", sBase64);
                    oActionBinding.setParameter("file_name", sFileName);

                    oActionBinding.invoke().then(function () {
                        MessageToast.show("Upload completed successfully!");
                        // Refresh the list
                        that.base.getExtensionAPI().refresh();
                    }).catch(function (oError) {
                        MessageBox.error("Upload failed: " + (oError.message || "Unknown error"));
                    });

                    document.body.removeChild(oFileInput);
                };

                oReader.readAsDataURL(oFile);
            });

            // Trigger file picker
            oFileInput.click();
        }
    });
});