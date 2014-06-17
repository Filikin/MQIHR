public with sharing class UpdateEmployeeContractDetails 
{
	Contact employee;
	List<Schema.FieldSetMember> contractFields = null;
	List<Schema.FieldSetMember> employeeFields = null;

    public UpdateEmployeeContractDetails()
    {
        employee = null;
 		contractFields = getFields ('MapContractToEmployee', true);
    	employeeFields = getFields ('MapContractToEmployee', false);
    }

	public void UpdateFromContractList (List<Employment_Contract__c> cpList)
    {
        // get the list of employees affected and copy the latest contract into the employee fields
        Set <ID> employees = new Set<ID>();
        for(Employment_Contract__c hra: cpList)
        {
        	employees.add (hra.Employee__c);
        }
        UpdateSetOfEmployees (employees);
    }

    public void UpdateSetOfEmployees (Set <ID> employees)
    {
    	List<Contact> emps = createContactQuery (employees);
    	for (Contact oneEmployee: emps)
    		UpdateOneEmployee (oneEmployee);
    	update emps;
    }
    
    public void UpdateOneEmployee (Contact oneEmp)
    {
    	Employment_Contract__c latestContract = oneEmp.Job_Descriptions__r[0];
	   	for (Integer i=0; i<contractFields.size(); i++)
	   	{
	   		try
	   		{
	    		String fieldName = contractFields[i].getFieldPath();
		    	Schema.DisplayType fieldType = contractFields[i].getType();
    			system.debug ('Field is ' + fieldName + ' type is ' + fieldType);
    			
	    		if (fieldType == DisplayType.Date && isValidDate((Date)(latestContract.get(fieldName))))
	    		{
	    			system.debug ('Field is Date ' + fieldName);
	    			String contactFieldName = employeeFields[i].getFieldPath().replace('Employee__r.','');
	    			oneEmp.put(contactFieldName, (Date)(latestContract.get(fieldName)));
	    		}
		    	else if ((fieldType == DisplayType.Double || fieldType == DisplayType.Currency) && isValidDecimal((Decimal)(latestContract.get(fieldName))))
		    	{
    				system.debug ('Field is Decimal ' + fieldName);
     				String contactFieldName = employeeFields[i].getFieldPath().replace('Employee__r.','');
				    oneEmp.put(contactFieldName, (Decimal)(latestContract.get(fieldName)));
		    	}
		    	else if (fieldType == DisplayType.Boolean)
		    	{
    				system.debug ('Field is Boolean ' + fieldName);
    				Schema.DisplayType destFieldType = employeeFields[i].getType();
    				String contactFieldName = employeeFields[i].getFieldPath().replace('Employee__r.','');
				    if (destFieldType == DisplayType.Boolean) oneEmp.put(contactFieldName, (Boolean)(latestContract.get(fieldName)));
				    else oneEmp.put(contactFieldName, (Boolean)(latestContract.get(fieldName))?1:0);
			    }
    			else if (isValid((String)(latestContract.get(fieldName)))) 
    			{
    				system.debug ('Field is String ' + fieldName + ' path is ' + contractFields[i].getFieldPath());
    				String contactFieldName = employeeFields[i].getFieldPath().replace('Employee__r.','');
				    oneEmp.put(contactFieldName, (String)(latestContract.get(fieldName)));
			    }
	   		}
		    catch (Exception e)
		    {
		    	system.debug ('Error copying fields to Employee: ' + e.getMessage());
    		}
	   	}    	
    }
    
    
    
    public List<Contact> createContactQuery (Set<ID> employees)
	{
		String soql = getSelectStatement (employeeFields);
		soql += 'ID, (' + getSelectStatement (contractFields);
		soql += 'ID FROM Job_Descriptions__r order by Effective_Date__c DESC) ';
		
		soql += 'FROM Contact where ID in :employees';
		
		System.debug('SOQL Statement: ' + soql);
	    return database.query(soql);
	}
    
    public static String getSelectStatement (List<Schema.FieldSetMember> fieldList)
 	{
 		String query = 'SELECT ';
        for(Schema.FieldSetMember f : fieldList) {
            query += f.getFieldPath().replace('Employee__r.','') + ', ';
        }
        return query;
 	}
    
    public List<Schema.FieldSetMember> getFields(String fieldSetName, Boolean bContractFields) 
    {
    	Schema.FieldSet fs1 = Schema.SObjectType.Employment_Contract__c.fieldSets.getMap().get(fieldSetName);
    	List<Schema.FieldSetMember> allFields = fs1.getFields();
     	List<Schema.FieldSetMember> returnFields = new List<Schema.FieldSetMember>();
    	
    	Integer start = bContractFields ? 0:1;
    	for (Integer i=start; i<allFields.size(); i+=2)
    	{
			returnFields.add (allFields[i]);    		
    	}
    	return returnFields;
    }
    
   	public static boolean isValid (String text)
	{
		if (text <> null && text <> '' && text <> '[not provided]') return true;
		else return false;
	}
	
	public static boolean isValidDate (Date text)
	{
		if (text <> null) return true;
		else return false;
	}
	
	public static boolean isValidDecimal (Decimal text)
	{
		if (text <> null) return true;
		else return false;
	}
}