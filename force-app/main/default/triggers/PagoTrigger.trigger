trigger PagoTrigger on Pago__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PagoTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            PagoTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            PagoTriggerHandler.handleAfterDelete(Trigger.old);
        } else if (Trigger.isUndelete) {
            PagoTriggerHandler.handleAfterUndelete(Trigger.new);
        }
    }
}
