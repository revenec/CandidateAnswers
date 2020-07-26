public with sharing class SalesforceQuestionerAnswers {
    public SalesforceQuestionerAnswers() 
    {
        System.debug(LoggingLevel.INFO,'TEst init');
        question1();
        question2();
        question3();
        question4();
        question5();
        question6();
        question7();
        question8();
        

    }

    private void question1()
    {
        /*Question 1
         Create an algorithm that prints the integers from 17 to 53. However for multiples of two, print "Foo" instead of 
         the number and for multiples of five print "Bar". For numbers which are multiples of both two and five print "FooBar".*/

         for(Integer i = 17; i <= 53;i++)
         {
             
             if(Math.mod(i,2) == 0 && Math.mod(i,5) == 0)
             {
                System.debug('FooBar');
             }
             else if(Math.mod(i,2) == 0)
             {
                System.debug('Foo');
             }
             else if(Math.mod(i,5) == 0)
             {
                System.debug('Bar');
             }
             else {
                 System.debug(i);
             }
         }
    }

    private void question2()
    {
        /*Question 2
         In a relational database, why is redundant data (i.e. the same data stored in multiple tables) generally a bad thing?*/
         
         //ANSWER:
         Having redundant data in a database makes difficult to keep the records updated
         In Salesforce also, redundant data is a waste of money as you pay for how much storage you consume in the org

    }

    private void question3()
    {
        /*Question 3
        In a relational database, why might redundant data be necessary in real world applications?*/
        //ANSWER:
        The only reason I can think of is to have data backups 
    }
    private void question4()
    {
        /*Question 4
        In development teams, multiple people are often involved in building and maintaining a single salesforce instance. 
        They may be working on a single task together, or multiple tasks, and changes made by one developer may conflict with 
        those of another. What system would you suggest to help manage this, and why would you choose your solution in particular?*/

        //ANSWER
        If we are considering to modify an existing record in salesforce, I would stop users updating or deleting the record if anyone else is working with this record. Once the user
        who is working with this records finishes and save the changes, another user could update the record. I prefer this option to ensure that any user can modify a record which
        is currently used as this action could contaminate the existing data.
        
        On another hand, if we are speaking about version control, in my opinion there are two tools that any team should have working in the same Salesforce instance:
        - One is a platform for version control. I would suggest github because of the web interface and how easy it is to implement in one IDE.
        - Another one would be clear communication and coordination in the team about who is going to push changes, in this case we ensure that all the team will be modifying the existing version.

    }
    private void question5()
    {
        /*Question 5
        The below Salesforce Apex code may fail on any line with a DMLException. Modify the code to ensure that 
        if it were to fail then no data would be saved.

        Database.insert(action);
        Database.update(actionPlan);
        Database.update(customer);*/
        
        //ANSWER:
        System.SavePoint sp = Database.setSavePoint();
    
        try
        {
            Database.insert(action);
            Database.update(actionPlan);
            Database.update(customer);
            
        }
        catch(DMLException e)
        {
            Database.rollback(sp);
        }
    }
    private void question6()
    {
        /*Question 6
        What is the difference between Trigger.old and Trigger.new? Under which types of trigger are they each available?*/

        //ANSWER:
        The difference betwen Trigger.old and Trigger.new is that Trigger.old contains the records before been updated with the new values and the Trigger.new contains
        the records after been inserted or updated

        We can find Trigger.old when:
        Before update a record, after update a record, before delete a record and after delete a record

        We can find Trigger.new when:
        Before create a record, after create a record, before update a record and after update a record
    }
    private void question7()
    {
        /*Question 7
        Provide Salesforce Apex code which uses SOQL to extract the following fields from a custom object named Visitors into 
        a List variable. Only records where the value of the Company__c field is equal to Bluetel should be retrieved.

        Id
        Name
        Visit_Time__c
        Visiting__c*/
        
        //ANSWER:
        List<Visitors> lstVisitors = [SELECT Id, Name, Visit_Time__c, Visiting__c FROM Visitors__c WHERE Company__c = 'Bluetel'];
    }
    private void question8()
    {
        /*Question 8
         The following provides one test scenario for the requirement "Insurance Requests for amounts less than $100,000 should not be submitted to the insurer, 
         and the user should be presented with an error if they attempt to make this submission". Summarise the minimum test cases that you would define for the entire requirement.

          Given I am completing an insurance request

          When I specify a cover amount of less than $100,000 AND I choose to submit my request

          THEN I should receive an error AND the request should not be submitted*/

        //ANSWER:
        Case scenario 2
        Given I am completing an insurance request
        When I specify a cover amount of $100,000 AND I choose to submit my request
        THEN I should not receive and error AND the request should be submitted

        Case scenario 3
        Given I am completing an insurance request
        When I specify a cover amount of more than $100,000 AND I choose to submit my request
        THEN I should not receive and error AND the request should be submitted
    }
}
