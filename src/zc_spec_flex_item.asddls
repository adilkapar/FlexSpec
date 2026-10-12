@EndUserText.label: 'Flex Specification - Consumption View (Items)'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true

@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}

define view entity ZC_SPEC_FLEX_ITEM
  as projection on ZR_SPEC_FLEX_ITEM
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Specification ID'
  key Specid,

      @EndUserText.label: 'Counter'
  key Counter,

      /* --- Attribute ID with Value Help from Config Table --- */
      @EndUserText.label: 'Attribute'
      @ObjectModel.text.element: ['AttributeDescription']
      @UI.textArrangement: #TEXT_LAST
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZVH_FLEX_ATTRIBUTES', element: 'AttributeId' }
      }]
      AttributeId,

      @Semantics.text: true
      @UI.hidden: true
      _AttributeText.Description     as AttributeDescription,

      /* --- Attribute Value with Context-Dependent Value Help --- */
      @EndUserText.label: 'Value'
      @ObjectModel.text.element: ['ValueDescription']
      @UI.textArrangement: #TEXT_LAST
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZVH_FLEX_ATTR_VALUES', element: 'AttributeValue' },
        additionalBinding: [{
          localElement: 'AttributeId',
          element: 'AttributeId',
          usage: #FILTER_AND_RESULT
        }]
      }]
      AttributeValue,

      @Semantics.text: true
      @UI.hidden: true
      _ValueText.ValueDescription    as ValueDescription,

      /* Parent association */
      _Header : redirected to parent ZC_SPEC_FLEX
}