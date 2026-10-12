@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flex Specification - Interface View (Header)'
@ObjectModel.usageType: {
  serviceQuality: #A,
  sizeCategory: #L,
  dataClass: #MASTER
}

define root view entity ZR_SPEC_FLEX
  as select from zspec_flex
  composition [0..*] of ZR_SPEC_FLEX_ITEM as _Items
{
  key specid             as Specid,
      spec_description   as SpecDescription,
      del_flag           as DelFlag,

      @Semantics.user.createdBy: true
      created_by         as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at         as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by    as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at    as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed as LocalLastChanged,

      /* Composition */
      _Items
}