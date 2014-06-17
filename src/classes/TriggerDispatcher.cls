public class TriggerDispatcher 
{
    public static Boolean InTrigger = false;
    public interface ITriggerEntry 
    {
        void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
            List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap);
    }
    
    public static ITriggerEntry activeFunction = null;
    
    public static void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
        List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
    {
        if (TriggerObject == 'HR_Absence__c' && isAfter)
        {
            activeFunction = new UpdateContactFromHRAbsenceClass();
            activeFunction.MainEntry (TriggerObject, isBefore, isDelete, isAfter, isInsert, isUpdate, isExecuting, newList, newMap, oldList, oldMap);
        }
        else if (TriggerObject == 'Employment_Contract__c' && isAfter)
        {
            activeFunction = new UpdateContactFromContract();
            activeFunction.MainEntry (TriggerObject, isBefore, isDelete, isAfter, isInsert, isUpdate, isExecuting, newList, newMap, oldList, oldMap);
        }
    }
}