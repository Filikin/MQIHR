public with sharing class UpdateContactFromHRAbsenceClass implements TriggerDispatcher.ITriggerEntry
{
    public void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
        List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
    {
        if (isInsert || isUpdate) HR_AbsenceUpdated (newList);
        else if (isDelete) HR_AbsenceDeleted (oldList);
    }

    public void HR_AbsenceUpdated (List<HR_Absence__c> cmList)
    {
    	UpdateContactController updateContacts = new UpdateContactController ();
        UpdateContacts.UpdateFromAbsenceList (cmList);
    }

    public void HR_AbsenceDeleted (List<HR_Absence__c> cmList)
    {
        HR_AbsenceUpdated (cmList);
    }

}