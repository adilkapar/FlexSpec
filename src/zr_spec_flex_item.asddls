@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flex Specification - Interface View (Items/EAV)'
@ObjectModel.usageType: {
  serviceQuality: #A,
  sizeCategory: #L,
  dataClass: #MASTER
}

define view entity ZR_SPEC_FLEX_ITEM
  as select from zspec_flex_i
  association to parent ZR_SPEC_FLEX as _Header on $projection.Specid = _Header.Specid

  /* Text association for Attribute ID description */
  association [0..1] to ZVH_FLEX_ATTRIBUTES as _AttributeText
    on $projection.AttributeId = _AttributeText.AttributeId

  /* Text association for Attribute Value description */
  association [0..1] to ZVH_FLEX_ATTR_VALUES as _ValueText
    on  $projection.AttributeId    = _ValueText.AttributeId
    and $projection.AttributeValue = _ValueText.AttributeValue
{
  key specid          as Specid,
  key counter         as Counter,
      attribute_id    as AttributeId,
      attribute_value as AttributeValue,

      /* Associations */
      _Header,
      _AttributeText,
      _ValueText
}