trigger PartidaRemisionTrigger on Partida_Remision__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PartidaRemisionTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            PartidaRemisionTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            PartidaRemisionTriggerHandler.handleAfterDelete(Trigger.old);
        } else if (Trigger.isUndelete) {
            PartidaRemisionTriggerHandler.handleAfterUndelete(Trigger.new);
        }
    }
}
