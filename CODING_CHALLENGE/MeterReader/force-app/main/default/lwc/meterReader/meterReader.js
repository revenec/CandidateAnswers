
import CUSTOMER_ID from '@salesforce/schema/Meter_Reader__c.CustomerNameLgt__c';
import METER_ID from '@salesforce/schema/Meter_Reader__c.MeterNameLgt__c';
import SUPPLIER_ID from '@salesforce/schema/Meter_Reader__c.SupplierNameLgt__c';
import TOTAL_CONSUMED from '@salesforce/schema/Meter_Reader__c.Total_Consumed__c';
import READ_DATE from '@salesforce/schema/Meter_Reader__c.Submited_DateTime__c';
import { LightningElement, wire } from 'lwc';
import getRecords from '@salesforce/apex/MeterReaderController.getRecords';
const COLUMNS = [
    { label: 'Customer ID', fieldName: CUSTOMER_ID.fieldApiName },
    { label: 'Meter ID', fieldName: METER_ID.fieldApiName},
    { label: 'Supplier ID', fieldName: SUPPLIER_ID.fieldApiName},
    { label: 'Total Consumed', fieldName: TOTAL_CONSUMED.fieldApiName, type: 'decimal' },
    { label: 'Received Date', fieldName: READ_DATE.fieldApiName, type: 'date'}
];

export default class MeterReader extends LightningElement 
{
    columns = COLUMNS;
    @wire(getRecords) meterReaders;  
}
