public with sharing class UpdateContactFromContract implements TriggerDispatcher.ITriggerEntry
{
    public void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
        List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
    {
        if (isInsert || isUpdate) ContractUpdated (newList);
    }

    public void ContractUpdated (List<Employment_Contract__c> cmList)
    {
    	UpdateEmployeeContractDetails updateContacts = new UpdateEmployeeContractDetails ();
        UpdateContacts.UpdateFromContractList (cmList);
    }
}