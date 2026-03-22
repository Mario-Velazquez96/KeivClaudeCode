trigger AportacionSocioTrigger on Aportacion_Socio__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AportacionSocioTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            AportacionSocioTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            AportacionSocioTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
}
