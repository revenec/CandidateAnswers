public with sharing class MeterReaderController 
{
    //Method to send the meter readers to the lightning web component.
    @AuraEnabled(cacheable=true)
    public static Meter_Reader__c[] getRecords()
    {
        //Return meter readers in the system sorted by create date.       
        return [SELECT Id, Name, CustomerNameLgt__c,MeterNameLgt__c, SupplierNameLgt__c, Total_Consumed__c, Submited_DateTime__c   
                FROM Meter_Reader__c 
                ORDER BY Submited_DateTime__c DESC
                LIMIT 10000];
    }
}
