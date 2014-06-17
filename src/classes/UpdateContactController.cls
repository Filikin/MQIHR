public with sharing class UpdateContactController 
{
	Contact employee;
    public UpdateContactController(ApexPages.StandardController controller)
    {
        employee = (Contact)controller.getRecord();
    }

    public UpdateContactController()
    {
        employee = null;
    }

	public pageReference UpdateSingleContact ()
	{
		UpdateSetOfEmployees (new Set<ID>{employee.Id});

        String returnURL = '/' + employee.ID;
        return new PageReference(returnURL);
	}
	
	public void UpdateFromAbsenceList (List<HR_Absence__c> cpList)
    {
        // get the list of employees affected and summarise their certified and uncertified sick leave in past 12 months
        Set <ID> employees = new Set<ID>();
        for(HR_Absence__c hra: cpList)
        {
            if (hra.Type__c.contains('Sick') && !hra.Type__c.contains('probation')) employees.add (hra.Employee__c);
        }
        UpdateSetOfEmployees (employees);
    }
    
    public void UpdateSetOfEmployees (Set <ID> employees)
    {
        List <Contact> affectedEmployees = [SELECT ID, Last_absence_calculation__c, Certified_Sick_Leave_in_last_12_months__c, Uncertified_Sick_Leave_in_last_12_months__c, 
        	Sick_leave_scheme__c, Full_Pay_Sick_Leave_Entitlement__c, Half_Pay_Sick_Leave_Entitlement__c, Year_of_service__c, Hours_per_week__c, 
        	Sick_leave_in_last_4_years__c, X4_Year_sick_leave_remaining__c, Uncert_Paid_Sick_Leave_in_last_12_months__c, Contract_Start_Date__c,
            (SELECT Type__c, Start_Date__c, Number_of_hours__c, Office_notified_on_first_day_of_sickness__c, Employee_on_CE_Scheme__c FROM HR_Absences__r) FROM Contact where ID in :employees];
        for (Contact oneEmployee: affectedEmployees)
        {
        	UpdateOneEmployee (oneEmployee);
        }
        update affectedEmployees;
    }
    
    public void UpdateOneEmployee (Contact oneEmployee)
    {
    	Decimal oneDayInHours = oneEmployee.Hours_per_week__c/5;
     	Decimal oneMonthInHours = 21.6 * oneDayInHours;
     	Date startOfYear = Date.newInstance(system.today().year(), 1, 1);
     	
	    oneEmployee.Certified_Sick_Leave_in_last_12_months__c = 0;
        oneEmployee.Uncertified_Sick_Leave_in_last_12_months__c = 0;
        oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c = 0;
        oneEmployee.Sick_leave_in_last_4_years__c = 0;

		Integer sick_leave_scheme = 0;
        if (oneEmployee.Sick_leave_scheme__c != null && oneEmployee.Sick_leave_scheme__c != '')	sick_leave_scheme = Integer.valueOf (oneEmployee.Sick_leave_scheme__c.left(1));
        else return;

		Boolean CE_Employee = false;
    	if (sick_leave_scheme == 1 || sick_leave_scheme == 5) 
    	{
    		oneDayInHours = 8;
    		CE_Employee = true;
    	}
    	
		for (HR_Absence__c oneHRA: oneEmployee.HR_Absences__r)
		{
			try
			{
	       		if (oneHRA.Employee_on_CE_Scheme__c == 'Yes' && !CE_Employee) continue; // ignore absences where the employee was previously on a CE contract
	       		if (oneHRA.Number_of_hours__c == null) continue;
	       		
	            if ((oneHRA.Start_Date__c > system.today() - (365*4+1)) && (oneHRA.Type__c == 'Certified Sick' || oneHRA.Type__c == 'Uncertified Sick'))
	            {
	            	if (oneHRA.Type__c == 'Certified Sick')
	            	{
	            		oneEmployee.Sick_leave_in_last_4_years__c += oneHRA.Number_of_hours__c;
	            		// for CE Supervisors, this is the calendar year rather than the last 12 months
	            		// for CE employees, it is the start of current contract
	            		if (sick_leave_scheme == 1)
	            		{
	            			if (oneHRA.Start_date__c >= oneEmployee.Contract_Start_Date__c) 
	            			{
	            				oneEmployee.Certified_Sick_Leave_in_last_12_months__c += oneHRA.Number_of_hours__c;
	            			}
	            			system.debug ('Scheme 1, certified sick start date: ' + oneHRA.Start_date__c + ' Employee start date ' + oneEmployee.Contract_Start_Date__c + ' Number of hours ' + oneHRA.Number_of_hours__c);
	            		}
	            		else if (sick_leave_scheme == 5)
	            		{
	            			if (oneHRA.Start_Date__c >= startOfYear) oneEmployee.Certified_Sick_Leave_in_last_12_months__c += oneHRA.Number_of_hours__c;
	            		}
	            		else if (oneHRA.Start_Date__c > system.today() - 365) oneEmployee.Certified_Sick_Leave_in_last_12_months__c += oneHRA.Number_of_hours__c;
	            	}
	            	else // uncertified sick
	            	{
	            		if (sick_leave_scheme == 1)
	            		{
	            			if (oneHRA.Start_date__c >= oneEmployee.Contract_Start_Date__c) oneEmployee.Uncertified_Sick_Leave_in_last_12_months__c += oneHRA.Number_of_hours__c;
	            		}
	            		else if (sick_leave_scheme == 5)
	            		{
	            			if (oneHRA.Start_Date__c >= startOfYear) oneEmployee.Uncertified_Sick_Leave_in_last_12_months__c += oneHRA.Number_of_hours__c;
	            		}
	            		else if (oneHRA.Start_Date__c > system.today() - 365) 
	            		{
	            			oneEmployee.Uncertified_Sick_Leave_in_last_12_months__c += oneHRA.Number_of_hours__c;
	            		}
	            		// Paid uncertified sick
	            		if (oneHRA.Office_notified_on_first_day_of_sickness__c == 'Yes' || sick_leave_scheme == 2)
	            		{
	            			if (sick_leave_scheme == 5) // CE Supervisors get either 4 days from the start of the year or 5 days rolling year - for the moment stick with the DSP policy
	            			{
	            				if (oneHRA.Start_Date__c >= startOfYear)oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c += math.min (oneDayInHours*2, oneHRA.Number_of_hours__c);
	            			}
	            			else if (oneHRA.Start_Date__c > system.today() - 365) oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c += math.min (oneDayInHours*2, oneHRA.Number_of_hours__c);
	            			oneEmployee.Sick_leave_in_last_4_years__c += math.min (oneDayInHours*2, oneHRA.Number_of_hours__c);
	            		}
	            	}
	            }
			}
            catch (Exception e)
            {
            	system.debug ('UpdateOneEmployee Exception on a HRA ' + e.getMessage());
            	continue;
            }
    }
        
     	if (sick_leave_scheme == 1)
    	{
    		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = 56;
    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = 0;
    		oneEmployee.X4_Year_sick_leave_remaining__c = 0; // not really relevant for CE employees
    		oneEmployee.X4_Year_sick_leave_entitlement__c = 0;
    		oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c = 0;
    	}
    	else if (sick_leave_scheme == 2)
    	{
    		if (oneEmployee.Year_of_service__c == 1 || oneEmployee.Year_of_service__c == 2)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * oneEmployee.Year_of_service__c;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * oneEmployee.Year_of_service__c;
    		}
    		else if (oneEmployee.Year_of_service__c == 3)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * 4;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * 4;
    		}
    		else if (oneEmployee.Year_of_service__c == 4 || oneEmployee.Year_of_service__c == 5)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * 5;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * 5;
    		}
     		else if (oneEmployee.Year_of_service__c >= 6)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * 6;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneMonthInHours * 6;
    		}
    		oneEmployee.X4_Year_sick_leave_entitlement__c = oneMonthInHours*12; // this may change to be pro-rata
    		oneEmployee.X4_Year_sick_leave_remaining__c = oneEmployee.X4_Year_sick_leave_entitlement__c - oneEmployee.Sick_leave_in_last_4_years__c;
    		oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c = math.min (oneEmployee.Hours_per_week__c*2, oneEmployee.Uncertified_Sick_Leave_in_last_12_months__c);
    	}
    	else if (sick_leave_scheme == 3)
    	{
    		if (oneEmployee.Year_of_service__c == 1 || oneEmployee.Year_of_service__c == 2)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 4 * oneEmployee.Year_of_service__c;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 4 * oneEmployee.Year_of_service__c;
    		}
    		else if (oneEmployee.Year_of_service__c == 3)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 10;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 10;
    		}
    		else if (oneEmployee.Year_of_service__c == 4)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 12;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 12;
    		}
    		else if (oneEmployee.Year_of_service__c == 5)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 14;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 14;
    		}
     		else if (oneEmployee.Year_of_service__c >= 6)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 16;
	    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 16;
    		}
    		oneEmployee.X4_Year_sick_leave_entitlement__c = oneEmployee.Hours_per_week__c * 32;
    		oneEmployee.X4_Year_sick_leave_remaining__c = oneEmployee.X4_Year_sick_leave_entitlement__c - oneEmployee.Sick_leave_in_last_4_years__c;
     		oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c = math.min (oneEmployee.Hours_per_week__c, oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
    	}
    	else if (sick_leave_scheme == 4)
    	{
    		if (oneEmployee.Year_of_service__c < 6)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 2 * oneEmployee.Year_of_service__c;
    		}
     		else if (oneEmployee.Year_of_service__c >= 6)
    		{
        		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = oneEmployee.Hours_per_week__c * 12;
    		}
    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = 0;
    		oneEmployee.X4_Year_sick_leave_entitlement__c = oneEmployee.Hours_per_week__c * 12;
    		oneEmployee.X4_Year_sick_leave_remaining__c = oneEmployee.X4_Year_sick_leave_entitlement__c - oneEmployee.Sick_leave_in_last_4_years__c;
     		oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c = math.min (oneEmployee.Hours_per_week__c, oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
    	}
    	else if (sick_leave_scheme == 5) // CE Supervisor
    	{
     		oneEmployee.Full_Pay_Sick_Leave_Entitlement__c = 18 * oneDayInHours; // 14 days certified, 4 days uncertified
    		oneEmployee.Half_Pay_Sick_Leave_Entitlement__c = 0;
    		oneEmployee.X4_Year_sick_leave_remaining__c = 0; // not really relevant for CE employees
    		oneEmployee.X4_Year_sick_leave_entitlement__c = 0;
    		oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c = math.min (4 * oneDayInHours, oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
    		
    	}
    	
		if (oneEmployee.X4_Year_sick_leave_remaining__c < 0) oneEmployee.X4_Year_sick_leave_remaining__c = 0;
		
		oneEmployee.Full_Pay_Sick_Leave_remaining1__c = oneEmployee.Full_Pay_Sick_Leave_Entitlement__c - (oneEmployee.Certified_Sick_Leave_in_last_12_months__c + oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c);
		
		if (CE_Employee)
		{
			oneEmployee.Half_Pay_Sick_Leave_remaining1__c = 0;
		}
		else
		{
			if (oneEmployee.X4_Year_sick_leave_remaining__c == 0 || oneEmployee.Full_Pay_Sick_Leave_remaining1__c < 0) oneEmployee.Full_Pay_Sick_Leave_remaining1__c = 0;
			if (oneEmployee.X4_Year_sick_leave_remaining__c < oneEmployee.Full_Pay_Sick_Leave_remaining1__c) oneEmployee.Full_Pay_Sick_Leave_remaining1__c = oneEmployee.X4_Year_sick_leave_remaining__c;
		
			if (oneEmployee.Full_Pay_Sick_Leave_remaining1__c > 0) oneEmployee.Half_Pay_Sick_Leave_remaining1__c = oneEmployee.Half_Pay_Sick_Leave_Entitlement__c;
			else 
			{
				oneEmployee.Half_Pay_Sick_Leave_remaining1__c = oneEmployee.Half_Pay_Sick_Leave_Entitlement__c - (oneEmployee.Certified_Sick_Leave_in_last_12_months__c + oneEmployee.Uncert_Paid_Sick_Leave_in_last_12_months__c - oneEmployee.Full_Pay_Sick_Leave_Entitlement__c);
				if (oneEmployee.X4_Year_sick_leave_remaining__c == 0 || oneEmployee.Half_Pay_Sick_Leave_remaining1__c < 0) oneEmployee.Half_Pay_Sick_Leave_remaining1__c = 0;
				if (oneEmployee.X4_Year_sick_leave_remaining__c < oneEmployee.Half_Pay_Sick_Leave_remaining1__c) oneEmployee.Half_Pay_Sick_Leave_remaining1__c = oneEmployee.X4_Year_sick_leave_remaining__c;
			}
		}
        oneEmployee.Last_absence_calculation__c = system.today();
    }
		
}