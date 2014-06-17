@isTest
private class UpdateContactTests 
{
    static List<Contact> createTestObjects (Integer numberOfContacts)
    {
        List<Contact> contacts = new List<Contact>();
        for (Integer i=1; i<=numberOfContacts; i++)
        {
            Contact newContact = new Contact (firstName='Fred'+i, lastName='Test'+i, BirthDate=Date.newInstance (1993, 2, i), Start_date__c=system.today()-100);
	     	newContact.Sick_leave_scheme__c = '2. Scheme 2';
            contacts.add(newContact);
        }
        insert contacts;
        
        List<HR_Absence__c> hra = new List<HR_Absence__c>();
        List<Employment_Contract__c> ecl = new List<Employment_Contract__c>();
        for (Contact oc: contacts)
        {
            hra.add (new HR_Absence__c (Employee__c = oc.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-40, Number_of_hours__c=70, Type__c='Certified Sick'));
            hra.add (new HR_Absence__c (Employee__c = oc.id, Start_Date__c = system.today() - 60, Finish_Date__c = system.today()-59, Number_of_hours__c=7, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='Yes'));
            hra.add (new HR_Absence__c (Employee__c = oc.id, Start_Date__c = system.today() - 100, Finish_Date__c = system.today()-90, Number_of_hours__c=70, Type__c='Holiday'));
            
            ecl.add (new Employment_Contract__c (Employee__c = oc.id, Effective_Date__c = system.today()));
        }
        insert hra;
        insert ecl;
        return contacts;
    }

    static testMethod void testHRAbsenceCreated ()
    {
        List<Contact> newContacts = createTestObjects (5);
        Contact oneContact = [select ID, Uncertified_Sick_Leave_in_last_12_months__c, Certified_Sick_Leave_in_last_12_months__c from Contact limit 1];
        system.assertEquals (70, oneContact.Certified_Sick_Leave_in_last_12_months__c);
        system.assertEquals (7, oneContact.Uncertified_Sick_Leave_in_last_12_months__c);
    }

    static testMethod void testContractCreated ()
    {
        List<Contact> newContacts = createTestObjects (5);
        Contact oneContact = [select ID, Contract_Start_Date__c from Contact limit 1];
        system.assertEquals (system.today(), oneContact.Contract_Start_Date__c);
    }

    static testMethod void testHRAbsenceUpdated ()
    {
        List<Contact> newContacts = createTestObjects (5);
        Contact oneContact = [select ID, Uncertified_Sick_Leave_in_last_12_months__c, Certified_Sick_Leave_in_last_12_months__c from Contact limit 1];
        oneContact.Sick_leave_scheme__c = '2. second';
        update oneContact;
        
        List<HR_Absence__c>toUpdate = [select ID, Type__c from HR_Absence__c where Type__c = 'Uncertified Sick' and Employee__c = :oneContact.id];
        toUpdate[0].Type__c = 'Certified Sick';
        update toUpdate[0];
        oneContact = [select ID, Uncertified_Sick_Leave_in_last_12_months__c, Certified_Sick_Leave_in_last_12_months__c from Contact limit 1];
        system.assertEquals (77, oneContact.Certified_Sick_Leave_in_last_12_months__c);
     }

    static testMethod void testHRAbsenceDeleted ()
    {
        List<Contact> newContacts = createTestObjects (5);
        Contact oneContact = [select ID, Uncertified_Sick_Leave_in_last_12_months__c, Certified_Sick_Leave_in_last_12_months__c from Contact limit 1];
        List<HR_Absence__c>toDelete = [select ID from HR_Absence__c where Type__c = 'Uncertified Sick' and Employee__c = :oneContact.id];
        delete toDelete;
        oneContact = [select ID, Uncertified_Sick_Leave_in_last_12_months__c, Certified_Sick_Leave_in_last_12_months__c from Contact limit 1];
        system.assertEquals (70, oneContact.Certified_Sick_Leave_in_last_12_months__c);
        system.assertEquals (0, oneContact.Uncertified_Sick_Leave_in_last_12_months__c);
 
     }

    static testMethod void testRefreshHRAbsence ()
    {
        List<Contact> newContacts = createTestObjects (1);
        Contact oneContact = [select ID, Uncertified_Sick_Leave_in_last_12_months__c, Certified_Sick_Leave_in_last_12_months__c from Contact limit 1];
        List<HR_Absence__c>toUpdate = [select ID, Type__c from HR_Absence__c where Type__c = 'Uncertified Sick' and Employee__c = :oneContact.id];
        toUpdate[0].Type__c = 'Certified Sick';
        update toUpdate[0];
        
        oneContact.Sick_leave_scheme__c = '1. CE';
        update oneContact;

        ApexPages.StandardController contactController = new ApexPages.StandardController(oneContact);
        UpdateContactController ucc = new UpdateContactController(contactController);
        ucc.UpdateSingleContact();
     }
     
     static testMethod void testSickLeaveScheme1 ()
     {
     	Contact employee = new Contact (firstName='Fred', lastName='Test', BirthDate=Date.newInstance (1993, 2, 12), Start_date__c=system.today()-100);
     	employee.Sick_leave_scheme__c = '1. CE';
     	insert employee;
     	
     	Employment_Contract__c ec = new Employment_Contract__c (Employee__c=employee.id, Effective_Date__c=system.today()-100);
     	insert ec;
     	
     	HR_Absence__c hra = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Certified Sick');
     	insert hra;
     	
       	HR_Absence__c hra3 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='No');
     	insert hra3;

        employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c, Contract_Start_Date__c, Uncertified_Sick_Leave_in_last_12_months__c from Contact where ID=:employee.id];
        system.assertEquals (35, employee.Uncertified_Sick_Leave_in_last_12_months__c);
        system.assertEquals(system.today()-100, employee.Contract_Start_Date__c);
        system.assertEquals (21, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (0, employee.Half_Pay_Sick_Leave_remaining1__c);
     }

	static Decimal oneMonthInHours = 21.6 * 7;
     static testMethod void testSickLeaveScheme2 ()
     {
     	Contact employee = new Contact (firstName='Fred', lastName='Test', BirthDate=Date.newInstance (1993, 2, 12), Start_date__c=system.today()-100);
     	employee.Sick_leave_scheme__c = '2. Scheme 2';
     	insert employee;
     	
     	HR_Absence__c hra = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Certified Sick');
     	insert hra;
     	
        employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c from Contact where ID=:employee.id];
        system.assertEquals (oneMonthInHours-35, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (oneMonthInHours, employee.Half_Pay_Sick_Leave_remaining1__c);
     	
     	employee.Start_Date__c=system.today()-3650;
     	update employee;
     	HR_Absence__c hra2 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='Yes');
     	insert hra2;
  	    
  	    employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c, Uncertified_Sick_Leave_in_last_12_months__c from Contact where ID=:employee.id];
        system.assertEquals (35, employee.Uncertified_Sick_Leave_in_last_12_months__c);
        system.assertEquals (oneMonthInHours*6-70, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (oneMonthInHours*6, employee.Half_Pay_Sick_Leave_remaining1__c);
     }

     static testMethod void testSickLeaveScheme3 ()
     {
     	Contact employee = new Contact (firstName='Fred', lastName='Test', BirthDate=Date.newInstance (1993, 2, 12), Start_date__c=system.today()-100);
     	employee.Sick_leave_scheme__c = '3. Scheme 3';
     	insert employee;
     	
     	HR_Absence__c hra = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Certified Sick');
     	insert hra;
     	
        employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c from Contact where ID=:employee.id];
        system.assertEquals (105, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (140, employee.Half_Pay_Sick_Leave_remaining1__c);
     	
     	employee.Start_Date__c=system.today()-3650;
     	update employee;
     	HR_Absence__c hra2 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='Yes');
     	insert hra2;
  	    
  	    employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c, Uncertified_Sick_Leave_in_last_12_months__c, Uncert_Paid_Sick_Leave_in_last_12_months__c from Contact where ID=:employee.id];
        system.assertEquals (35, employee.Uncertified_Sick_Leave_in_last_12_months__c);
  	    system.assertEquals (14, employee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
        system.assertEquals (511, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (560, employee.Half_Pay_Sick_Leave_remaining1__c);
     }

     static testMethod void testSickLeaveScheme4 ()
     {
     	Contact employee = new Contact (firstName='Fred', lastName='Test', BirthDate=Date.newInstance (1993, 2, 12), Start_date__c=system.today()-100);
     	employee.Sick_leave_scheme__c = '4. Scheme 4';
     	insert employee;
     	
     	HR_Absence__c hra = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Certified Sick');
     	insert hra;
     	
        employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c from Contact where ID=:employee.id];
        system.assertEquals (35, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (0, employee.Half_Pay_Sick_Leave_remaining1__c);
     	
     	employee.Start_Date__c=system.today()-3650;
     	update employee;
     	HR_Absence__c hra2 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='Yes');
     	insert hra2;
  	    
     	HR_Absence__c hra3 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 50, Finish_Date__c = system.today()-45, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='Yes', Employee_on_CE_Scheme__c='Yes');
     	insert hra3;
  	    
  	    employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c, Uncertified_Sick_Leave_in_last_12_months__c, Uncert_Paid_Sick_Leave_in_last_12_months__c from Contact where ID=:employee.id];
        system.assertEquals (35, employee.Uncertified_Sick_Leave_in_last_12_months__c);
 	    system.assertEquals (14, employee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
        system.assertEquals (371, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (0, employee.Half_Pay_Sick_Leave_remaining1__c);
     }
     
     static testMethod void testSickLeaveScheme5 ()
     {
     	Contact employee = new Contact (firstName='Fred', lastName='Test5', BirthDate=Date.newInstance (1993, 2, 12), Start_date__c=system.today()-100);
     	employee.Sick_leave_scheme__c = '5. CE Supervisor';
     	insert employee;
     	
     	HR_Absence__c hra = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 6, Finish_Date__c = system.today()-1, Number_of_hours__c=35, Type__c='Certified Sick');
     	insert hra;
     	
        employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c from Contact where ID=:employee.id];
        system.assertEquals (109, employee.Full_Pay_Sick_Leave_remaining1__c);
        system.assertEquals (0, employee.Half_Pay_Sick_Leave_remaining1__c);
  
       	HR_Absence__c hra2 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 6, Finish_Date__c = system.today()-1, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='Yes');
     	insert hra2;

  	    employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c, Uncert_Paid_Sick_Leave_in_last_12_months__c from Contact where ID=:employee.id];
  	    system.assertEquals (16, employee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
        system.assertEquals (93, employee.Full_Pay_Sick_Leave_remaining1__c);

       	HR_Absence__c hra3 = new HR_Absence__c (Employee__c = employee.id, Start_Date__c = system.today() - 6, Finish_Date__c = system.today()-1, Number_of_hours__c=35, Type__c='Uncertified Sick', Office_notified_on_first_day_of_sickness__c='No', Employee_on_CE_Scheme__c='Yes');
     	insert hra3;

  	    employee = [select ID, Full_Pay_Sick_Leave_remaining1__c, Half_Pay_Sick_Leave_remaining1__c, Uncertified_Sick_Leave_in_last_12_months__c, Uncert_Paid_Sick_Leave_in_last_12_months__c from Contact where ID=:employee.id];
        system.assertEquals (70, employee.Uncertified_Sick_Leave_in_last_12_months__c);
 	    system.assertEquals (16, employee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
        system.assertEquals (93, employee.Full_Pay_Sick_Leave_remaining1__c);
     }

     
}