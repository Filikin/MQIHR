trigger Employment_Contract_Trigger on Employment_Contract__c (after insert, after update) 
{
    TriggerDispatcher.MainEntry ('Employment_Contract__c', trigger.isBefore, trigger.isDelete, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isExecuting,
        trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
}