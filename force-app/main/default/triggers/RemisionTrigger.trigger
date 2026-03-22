trigger RemisionTrigger on Remision__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        RemisionTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
