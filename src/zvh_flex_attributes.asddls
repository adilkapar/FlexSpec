@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flex Spec - Attribute ID Value Help'
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}
@Search.searchable: true

define view entity ZVH_FLEX_ATTRIBUTES
  as select from zspec_flex_cmap
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'Description' ]
  key logical_field as AttributeId,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      description    as Description,

      charc_name     as CharacteristicName,
      sort_order     as SortOrder,
      is_mandatory   as IsMandatory
}