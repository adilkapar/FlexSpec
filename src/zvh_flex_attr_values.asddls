@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flex Spec - Attribute Value Help (Context-Dependent)'
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}
@Search.searchable: true

define view entity ZVH_FLEX_ATTR_VALUES
  as select from ZVH_CHARC_VALUES as CharcVal
    inner join   zspec_flex_cmap  as Map on CharcVal.CharacteristicName = Map.charc_name
{
      @Search.defaultSearchElement: true
  key Map.logical_field              as AttributeId,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'ValueDescription' ]
  key CharcVal.CharacteristicValue   as AttributeValue,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      CharcVal.ValueDescription      as ValueDescription,

      CharcVal.CharacteristicName    as CharacteristicName
}
where Map.logical_field is not initial
  and Map.charc_name    is not initial