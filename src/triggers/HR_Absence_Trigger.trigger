trigger HR_Absence_Trigger on HR_Absence__c (after delete, after insert, after undelete, after update) 
{
    TriggerDispatcher.MainEntry ('HR_Absence__c', trigger.isBefore, trigger.isDelete, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isExecuting,
        trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
}