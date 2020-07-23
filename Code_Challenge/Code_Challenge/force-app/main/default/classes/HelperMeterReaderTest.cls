@isTest(seeAllData=false)
public class HelperMeterReaderTest {
    
    public static String jsonTestMalFormated = '{ ' +
                                                '"customerId": "identifier123",' + 
                                                '"serialNumber 27263927192",' + 
                                                '"mpxn": "14582749",' +
                                                '"read": ' +
                                                    '{"type": "ANYTIME", "registerId": "387373", "value": "2729"},' +
                                                    '{"type": "NIGHT", "registerId": "387373", "value": "2892"}' +
                                                '],' + 
                                                '"readDate": "2017-11-20T16:19:48+00:00Z"' + 
                                                '}';
    
    public static String jsonTestMultiRecord =  '[{ ' +
                                                '"customerId": "identifier123",' + 
                                                '"serialNumber": "27263927192",' + 
                                                '"mpxn": "14582749",' +
                                                '"read": [' +
                                                    '{"type": "ANYTIME", "registerId": "387373", "value": "2729"},' +
                                                    '{"type": "NIGHT", "registerId": "387373", "value": "2892"}' +
                                                '],' + 
                                                '"readDate": "2017-11-20T16:19:48+00:00Z"' + 
                                                '},'+
                                                '{ ' +
                                                '"customerId": "identifier123",' + 
                                                '"serialNumber": "27263927192",' + 
                                                '"mpxn": "14582749",' +
                                                '"read": [' +
                                                    '{"type": "ANYTIME", "registerId": "387373", "value": "2729"},' +
                                                    '{"type": "NIGHT", "registerId": "387373", "value": "2892"}' +
                                                '],' + 
                                                '"readDate": "2017-11-20T16:19:48+00:00Z"' + 
                                                '}]';
        
    //This method will test the get data process using a ApexMockCallout, this method also test the url is valid
    @isTest
    static void testGetData() 
    {
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('POSTED',HelperMeterReader.getMeterReader('https://testscenario/meter-read'));
    }
    //This method will test the get data process using a ApexMockCallout, this method also test the url is valid and test for more than one meter reading
    @isTest
    static void testGetDataMultiMeterReading() 
    {
        MeterReaderHttpCalloutMock.jsonTest = jsonTestMultiRecord;
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('POSTED',HelperMeterReader.getMeterReader('https://testscenario/meter-read'));
    }
    //This method will test the get data process using a ApexMockCallout, this method also test the url is not valid
    @isTest
    static void testGetDataInvalidUrl() 
    {
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('INVALID_URL',HelperMeterReader.getMeterReader('https://testscenario/read'));
    }
    //This method will test what happens when there is not data in the JSON received
    @isTest
    static void testGetDataEmptyJSON() 
    {
        MeterReaderHttpCalloutMock.jsonTest = '';
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('MALFORMAT_JSON',HelperMeterReader.getMeterReader('https://testscenario/meter-read'));
    }
    //This method will test what happens when the JSON is not formatted correctly
    @isTest
    static void testGetDataWrongJSON() 
    {
        MeterReaderHttpCalloutMock.jsonTest = jsonTestMalFormated;
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('MALFORMAT_JSON',HelperMeterReader.getMeterReader('https://testscenario/meter-read'));
    }
    //This method will test what happens when connection fails
    @isTest
    static void testGetWhenErrorInConnection() 
    {
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('MALFORMAT_JSON',HelperMeterReader.getMeterReader('https://testscenario/meter-read/300'));
    }
    //This method will test to save data existing records in the org
    @isTest
    static void testSaveDataWithDataInOrg() 
    {
        createData();
        List<MeterReader> lstMeters = HelperMeterReader.validateJSONAndGenerateRecords(MeterReaderHttpCalloutMock.jsonTest);
        System.AssertEquals('OK',HelperMeterReader.storeRecords(lstMeters));
    }
    //This method will test the present data process
    @isTest
    static void testPostData()
    {
        List<MeterReader> lstMeters = HelperMeterReader.validateJSONAndGenerateRecords(MeterReaderHttpCalloutMock.jsonTest);
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('POSTED',HelperMeterReader.generatePresent(lstMeters,'https://testscenario/meter-read'));
    }

    //This method will test how the routine works when POSTING JSON when it is malformated
    @isTest
    static void testPostDataWithWrongJSON()
    {
     
        List<MeterReader> lstMeters = HelperMeterReader.validateJSONAndGenerateRecords(jsonTestMalFormated);
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('FAILED_PRESENT',HelperMeterReader.generatePresent(lstMeters,'https://testscenario/meter-read'));
    }
    //This method will test how the routine works when JSON is malformated
    @isTest
    static void testPostDataWitConnectionError()
    {
     
        List<MeterReader> lstMeters = HelperMeterReader.validateJSONAndGenerateRecords(MeterReaderHttpCalloutMock.jsonTest);
        Test.setMock(HttpCalloutMock.class, new MeterReaderHttpCalloutMock());
        System.AssertEquals('FAILED_POSTING',HelperMeterReader.generatePresent(lstMeters,'https://testscenario/meter-read/300'));
    }
    //Method to create dummy data to run the process
    public static void createData()
    {
        List<Customer__c> listCustomers = new List<Customer__c>();
        List<Meter__c> listMeters = new List<Meter__c>();
        Supplier__c supplier = new Supplier__c(Code__c = 'BG',External_ID__c = '14582749');

        Database.insert(supplier);

        listCustomers.add(new Customer__c(Customer_Email__c = 'tester1@test.es', Phone__c = '0754896325', External_ID__c = 'identifier123'));
        listCustomers.add(new Customer__c(Customer_Email__c = 'tester2@test.es', Phone__c = '0751489632'));

        Database.insert(listCustomers);

        listMeters.add(new Meter__c(Customer__c = listCustomers.get(0).Id, Supplier__c = supplier.Id, External_ID__c = '27263927192'));
        listMeters.add(new Meter__c(Customer__c = listCustomers.get(1).Id, Supplier__c = supplier.Id));

        Database.insert(listMeters);
    }
}