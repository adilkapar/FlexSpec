# FlexSpec RAP Application — Deployment Guide

## Prerequisites
- All CDS views, behavior definitions, and classes are activated in ADT ✅
- Database tables (`zspec_flex`, `zspec_flex_i`, `zspec_flex_cmap`, draft tables) are created ✅
- Number range object `ZNR_SPECF` is created with interval `01` ✅
- Config table `zspec_flex_cmap` has at least a few entries ✅

---

## STEP 1: Create Service Definition in ADT

1. In ADT Eclipse, right-click your package
2. Select **New** → **Other ABAP Repository Object**
3. Search for **Service Definition** → Click **Next**
4. Enter:
   - Name: `ZUI_SPEC_FLEX_O4`
   - Description: `Flex Specification - Service Definition`
5. Click **Next** → Select your transport request → **Finish**
6. Paste the following source code:

```cds
@EndUserText.label: 'Flex Specification - Service Definition'
define service ZUI_SPEC_FLEX_O4 {
  expose ZC_SPEC_FLEX      as SpecFlex;
  expose ZC_SPEC_FLEX_ITEM as SpecFlexItem;
  expose ZVH_FLEX_ATTRIBUTES  as FlexAttributes;
  expose ZVH_FLEX_ATTR_VALUES as FlexAttrValues;
}
```

7. Save and **Activate** (Ctrl+F3)

---

## STEP 2: Create Service Binding in ADT

1. Right-click your package
2. Select **New** → **Other ABAP Repository Object**
3. Search for **Service Binding** → Click **Next**
4. Enter:
   - Name: `ZUI_SPEC_FLEX_O4`
   - Description: `Flex Specification - OData V4 UI`
   - Binding Type: **OData V4 - UI**
   - Service Definition: `ZUI_SPEC_FLEX_O4` (browse or type)
5. Click **Next** → Select transport → **Finish**
6. **Activate** the service binding (Ctrl+F3)
7. Click the **Publish** button (top-right area of the editor)
8. Wait until the status shows **Published** (green indicator)

> **Note:** After publishing, the entity sets will appear in the left panel of the service binding editor.

---

## STEP 3: Test the App via Preview

1. In the Service Binding editor, you will see the entity set list:
   - `SpecFlex`
   - `SpecFlexItem`
   - `FlexAttributes`
   - `FlexAttrValues`
2. Select **SpecFlex**
3. Click the **Preview** button
4. A browser window opens with your Fiori Elements List Report app
5. Test the following:
   - [ ] Click **Create** → Verify Spec ID is auto-generated (SF...)
   - [ ] Fill in Description → Add items (Attribute + Value)
   - [ ] Save → Verify data is persisted
   - [ ] Test **Set Deletion Flag** / **Remove Deletion Flag** actions
   - [ ] Test **Upload Excel** action (if you have a test file ready)

---

## STEP 4: Generate the Fiori App in Business Application Studio (BAS)

### 4a. Open BAS and Create Project

1. Open **SAP Business Application Studio** (from BTP Cockpit)
2. Open your Dev Space (Full Stack Cloud Application or SAP Fiori)
3. From the Welcome page or menu: **View** → **Command Palette** → `Fiori: Open Application Generator`
4. Or use menu: **File** → **New Project from Template**

### 4b. Configure the Generator

| Step | Field | Value |
|------|-------|-------|
| Template | Template Type | **List Report Page** |
| Data Source | Data Source | **Connect to a System** |
| Data Source | System | Select your ABAP Environment (BTP or on-prem) |
| Data Source | Service | `ZUI_SPEC_FLEX_O4` (OData V4) |
| Entity Selection | Main Entity | `SpecFlex` |
| Entity Selection | Navigation Entity | `SpecFlexItem` (auto-populated) |
| Project Attributes | Module Name | `zflexspec` |
| Project Attributes | App Title | `Flex Specification Cabinet` |
| Project Attributes | Namespace | `z.flex.spec` |
| Project Attributes | Description | `Manage Flexible Manufacturing Specifications` |
| Project Attributes | Add deployment config | **Yes** |
| Project Attributes | Add FLP config | **Yes** |
| Deployment Config | Target | **ABAP** |
| Deployment Config | Destination | Your ABAP system |
| FLP Config | Semantic Object | `FlexSpec` |
| FLP Config | Action | `manage` |
| FLP Config | Title | `Flex Specification Cabinet` |

5. Click **Finish** → Project is generated

### 4c. Verify the Generated App (Optional)

1. Open terminal in BAS
2. Run: `npm start` (to preview locally with mock or live data)
3. Verify the List Report and Object Page render correctly

---

## STEP 5: Deploy the Fiori App to ABAP Repository

### 5a. Deploy via BAS

1. Right-click the project folder in BAS Explorer
2. Select **Deploy** → **Deploy to ABAP**
3. Or use terminal: `npm run deploy`
4. Fill in deployment details:
   - Target System: Your ABAP system
   - Package: Your development package (e.g., `ZFLEX`)
   - BSP Application Name: `ZFLEXSPEC`
   - BSP Application Description: `Flex Spec Cabinet Fiori App`
   - Transport Request: Select or create
5. Confirm and deploy
6. Wait for success message ✅

### 5b. Deploy via ADT (Alternative)

1. If you created the app locally, you can also deploy from VS Code using the `@sap/ux-ui5-tooling` deploy command

---

## STEP 6: Create IAM App (BTP ABAP Environment Only)

1. In ADT, right-click your package
2. **New** → **Other ABAP Repository Object** → Search **IAM App**
3. Enter:
   - Name: `ZFLEXSPEC_IAM`
   - Description: `Flex Spec Cabinet - IAM App`
   - Application Type: **EXT - UI - External App**
4. Click **Finish**
5. In the IAM App editor:
   - Go to the **Services** tab
   - Add Service: `ZUI_SPEC_FLEX_O4` (Service Type: OData V4)
6. **Activate** and **Publish**

---

## STEP 7: Create Business Catalog (BTP ABAP Environment Only)

1. In ADT, right-click your package
2. **New** → **Other ABAP Repository Object** → Search **Business Catalog**
3. Enter:
   - Name: `ZFLEXSPEC_BC`
   - Description: `Flex Spec Cabinet - Business Catalog`
4. Click **Finish**
5. In the Business Catalog editor:
   - Go to **Apps** tab
   - Add: `ZFLEXSPEC_IAM`
6. **Activate** and **Publish**

---

## STEP 8: Configure SAP Build Work Zone (Launchpad)

### 8a. Assign Content

1. Open **SAP Build Work Zone, standard edition** from BTP Cockpit
2. Go to **Content Manager** → **Content Explorer** tab
3. Find your ABAP system tile → Click it
4. Search for `ZFLEXSPEC_BC` (your business catalog)
5. Select it → Click **Add to My Content**

### 8b. Create a Group

1. Go to **Content Manager** → **My Content** tab
2. Click **+ New** → **Group**
3. Enter:
   - Title: `Flex Manufacturing`
   - Description: `Flexible Manufacturing Specification Apps`
4. In the **Apps** section → Toggle ON: `Flex Specification Cabinet`
5. **Save**

### 8c. Assign to a Role

1. Go to **Content Manager** → **My Content** tab
2. Find your Role (e.g., `Everyone` or a custom role)
3. Edit the role → Go to **Apps** section
4. Toggle ON: `Flex Specification Cabinet`
5. **Save**

### 8d. Verify in Site

1. Go to **Site Directory** → Open your site (or create one)
2. Click the **site URL** to open the Fiori Launchpad
3. You should see the **Flex Specification Cabinet** tile
4. Click it → Your app opens! 🎉

---

## Summary: Objects Checklist

| # | Object | Type | Name | Status |
|---|--------|------|------|--------|
| 1 | Database Table (Header) | Table | `ZSPEC_FLEX` | ☐ |
| 2 | Database Table (Items) | Table | `ZSPEC_FLEX_I` | ☐ |
| 3 | Database Table (Config) | Table | `ZSPEC_FLEX_CMAP` | ☐ |
| 4 | Draft Table (Header) | Table | `ZSPEC_FLEX_D` | ☐ |
| 5 | Draft Table (Items) | Table | `ZSPEC_FLEX_I_D` | ☐ |
| 6 | Number Range | SNRO | `ZNR_SPECF` | ☐ |
| 7 | Interface View (Header) | CDS | `ZR_SPEC_FLEX` | ☐ |
| 8 | Interface View (Items) | CDS | `ZR_SPEC_FLEX_ITEM` | ☐ |
| 9 | Consumption View (Header) | CDS | `ZC_SPEC_FLEX` | ☐ |
| 10 | Consumption View (Items) | CDS | `ZC_SPEC_FLEX_ITEM` | ☐ |
| 11 | Value Help (Attributes) | CDS | `ZVH_FLEX_ATTRIBUTES` | ☐ |
| 12 | Value Help (Attr Values) | CDS | `ZVH_FLEX_ATTR_VALUES` | ☐ |
| 13 | Behavior Definition (Root) | BDEF | `ZR_SPEC_FLEX` | ☐ |
| 14 | Behavior Definition (Proj) | BDEF | `ZC_SPEC_FLEX` | ☐ |
| 15 | Metadata Extension (Header) | DDLX | `ZMDE_C_SPEC_FLEX` | ☐ |
| 16 | Metadata Extension (Items) | DDLX | `ZMDE_C_SPEC_FLEX_ITEM` | ☐ |
| 17 | Behavior Implementation | Class | `ZBP_R_SPEC_FLEX` | ☐ |
| 18 | Service Definition | SRVD | `ZUI_SPEC_FLEX_O4` | ☐ |
| 19 | Service Binding | SRVB | `ZUI_SPEC_FLEX_O4` | ☐ |
| 20 | IAM App | IAM | `ZFLEXSPEC_IAM` | ☐ |
| 21 | Business Catalog | BC | `ZFLEXSPEC_BC` | ☐ |
| 22 | Fiori App (BSP) | BSP | `ZFLEXSPEC` | ☐ |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Service Binding won't publish | Check all CDS views and BDEF are activated without errors |
| Preview shows no data | Ensure draft tables exist and are activated |
| Value help dropdown empty | Check `zspec_flex_cmap` config table has entries AND characteristic values exist in CABN/CAWN |
| Number range error | Verify `ZNR_SPECF` exists with interval `01` (e.g., 0000000001 to 9999999999) |
| Draft errors in activation | Ensure draft table field names match CDS alias names (no underscores) |
| App not visible in Launchpad | Check IAM App → Business Catalog → Role assignment chain |