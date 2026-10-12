@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Generic Characteristic Value Help'
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}
@Search.searchable: true

define view entity ZVH_CHARC_VALUES
  as select from cabn as Chr
    inner join   cawn as Val on Chr.atinn = Val.atinn

  /* Text associations for descriptions */
    left outer join cabnt as ChrTxt on  Chr.atinn = ChrTxt.atinn
                                    and ChrTxt.spras = $session.system_language

    left outer join cawnt as ValTxt on  Val.atinn = ValTxt.atinn
                                    and Val.atzhl = ValTxt.atzhl
                                    and ValTxt.spras = $session.system_language
{
          @Search.defaultSearchElement: true
          @ObjectModel.text.element: [ 'CharacteristicDescription' ]
  key     Chr.atnam                             as CharacteristicName,

          @Search.defaultSearchElement: true
          @ObjectModel.text.element: [ 'ValueDescription' ]

          /* FIX: Use abap.dec(22,7) instead of abap.dec(15,3) to prevent overflow.
             dec(22,7) = 15 integer digits + 7 decimal digits = max 24 chars when cast to string.
             This fits in char(30) and handles values up to 999,999,999,999,999.
             Original dec(15,3) overflowed at values > 999,999,999,999.999 */
  key     case
            when Val.atwrt is not initial then Val.atwrt
            else cast( fltp_to_dec( Val.atflv as abap.dec(22,7) ) as abap.char(30) )
          end                                   as CharacteristicValue,

          @Semantics.text: true
          ChrTxt.atbez                          as CharacteristicDescription,

          @Semantics.text: true
          ValTxt.atwtb                          as ValueDescription
}
where Chr.atnam is not initial