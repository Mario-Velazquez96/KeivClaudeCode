trigger PartidaCotizacionTrigger on Partida_Cotizacion__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PartidaCotizacionTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            PartidaCotizacionTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            PartidaCotizacionTriggerHandler.handleAfterDelete(Trigger.old);
        } else if (Trigger.isUndelete) {
            PartidaCotizacionTriggerHandler.handleAfterUndelete(Trigger.new);
        }
    }
}
