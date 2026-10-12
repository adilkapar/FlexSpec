sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/ui/core/mvc/OverrideExecution",
    "sap/m/MessageBox",
    "sap/m/MessageToast"
], function (ControllerExtension, OverrideExecution, MessageBox, MessageToast) {
    "use strict";

    function _ensureXlsxLoaded(fnCallback, fnError) {
        if (typeof XLSX !== "undefined") {
            fnCallback();
            return;
        }
        var sLibPath = sap.ui.require.toUrl("flexspec") + "/lib/xlsx.full.min.js";
        var oScript = document.createElement("script");
        oScript.src = sLibPath;
        oScript.onload = function () {
            fnCallback();
        };
        oScript.onerror = function () {
            if (fnError) {
                fnError();
            } else {
                MessageBox.error("Failed to load Excel library (xlsx.full.min.js). Check webapp/lib/ folder.");
            }
        };
        document.head.appendChild(oScript);
    }

    return ControllerExtension.extend("flexspec.ext.UploadExtension", {

        metadata: {
            methods: {
                onDownloadTemplate: { "public": true, "final": false },
                onUploadExcel: { "public": true, "final": false }
            }
        },

        onDownloadTemplate: function () {
            var that = this;

            _ensureXlsxLoaded(function () {
                var oModel = that.base.getModel();
                var oListBinding = oModel.bindList("/FlexAttributes");

                oListBinding.requestContexts(0, 9999).then(function (aContexts) {
                    var aAttributes = aContexts.map(function (oCtx) {
                        return {
                            AttributeId: oCtx.getProperty("AttributeId"),
                            Description: oCtx.getProperty("Description") || ""
                        };
                    });

                    if (aAttributes.length === 0) {
                        MessageBox.warning("No attributes found in configuration table. Please maintain ZSPEC_FLEX_CMAP first.");
                        return;
                    }

                    var oWorkbook = XLSX.utils.book_new();

                    // Sheet 1: Header
                    var aHeaderData = [
                        ["ROW_ID", "DESCRIPTION"],
                        ["1", "(Enter spec description here)"],
                        ["2", "(Enter spec description here)"]
                    ];
                    var wsHeader = XLSX.utils.aoa_to_sheet(aHeaderData);
                    XLSX.utils.book_append_sheet(oWorkbook, wsHeader, "Header");

                    // Sheet 2: Items
                    var aItemData = [["ROW_ID", "ATTRIBUTE_ID", "ATTRIBUTE_VALUE", "ATTRIBUTE_DESCRIPTION (for reference only)"]];
                    aAttributes.forEach(function (attr) {
                        aItemData.push(["1", attr.AttributeId, "", attr.Description]);
                    });
                    aAttributes.forEach(function (attr) {
                        aItemData.push(["2", attr.AttributeId, "", attr.Description]);
                    });

                    var wsItems = XLSX.utils.aoa_to_sheet(aItemData);
                    wsItems["!cols"] = [{ wch: 8 }, { wch: 18 }, { wch: 25 }, { wch: 35 }];
                    XLSX.utils.book_append_sheet(oWorkbook, wsItems, "Items");

                    XLSX.writeFile(oWorkbook, "FlexSpec_Upload_Template.xlsx");
                    MessageToast.show("Template downloaded successfully.");

                }).catch(function (oError) {
                    MessageBox.error("Failed to read attributes: " + oError.message);
                });
            });
        },

        onUploadExcel: function () {
            var that = this;

            // Create hidden file input
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
                MessageToast.show("Processing: " + sFileName);

                var oReader = new FileReader();
                oReader.onload = function (e) {
                    var aBuffer = e.target.result;
                    var aUint8 = new Uint8Array(aBuffer);

                    // Convert ArrayBuffer to base64 for Edm.Binary
                    var sBinaryStr = "";
                    var iChunkSize = 8192;
                    for (var i = 0; i < aUint8.length; i += iChunkSize) {
                        var chunk = aUint8.subarray(i, i + iChunkSize);
                        sBinaryStr += String.fromCharCode.apply(null, chunk);
                    }
                    var sBase64 = btoa(sBinaryStr);

                    // Call static action via OData V4 model bindContext
                    var oModel = that.base.getModel();
                    var oActionODataContext = oModel.bindContext(
                        "/SpecFlex/com.sap.gateway.srvd.zsd_spec_flex.v0001.UploadExcel(...)"
                    );

                    oActionODataContext.setParameter("file_content", sBase64);
                    oActionODataContext.setParameter("file_name", sFileName);

                    MessageToast.show("Uploading to server...");

                    // execute() is the correct method (not invoke())
                    oActionODataContext.execute().then(function () {
                        MessageBox.success("Upload completed successfully!");
                        try {
                            that.base.getExtensionAPI().refresh();
                        } catch (ex) {
                            // silent
                        }
                    }).catch(function (oError) {
                        var sMsg = "Upload failed.";
                        try {
                            if (oError.message) {
                                sMsg += " " + oError.message;
                            }
                        } catch (ex) {
                            sMsg += " Check console for details.";
                        }
                        MessageBox.error(sMsg);
                        console.error("Upload Error:", oError);
                    });

                    document.body.removeChild(oFileInput);
                };

                oReader.readAsArrayBuffer(oFile);
            });

            oFileInput.click();
        }
    });
});