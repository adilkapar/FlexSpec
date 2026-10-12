@EndUserText.label: 'Flex Specification - Consumption View (Header)'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true

@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}

define root view entity ZC_SPEC_FLEX
  provider contract transactional_query
  as projection on ZR_SPEC_FLEX
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Specification ID'
  key Specid,

      @EndUserText.label: 'Description'
      @Search.defaultSearchElement: true
      SpecDescription,

      @EndUserText.label: 'Deletion Flag'
      DelFlag,

      @EndUserText.label: 'Created By'
      CreatedBy,

      @EndUserText.label: 'Created At'
      CreatedAt,

      @EndUserText.label: 'Last Changed By'
      LastChangedBy,

      @EndUserText.label: 'Last Changed At'
      LastChangedAt,

      @EndUserText.label: 'Local Last Changed'
      LocalLastChanged,

      /* Composition to Items */
      _Items : redirected to composition child ZC_SPEC_FLEX_ITEM
}