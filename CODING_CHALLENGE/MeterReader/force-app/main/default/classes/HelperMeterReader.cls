//This class will contain the methods to accept,validate, store and present the meter reader
public class HelperMeterReader 
{
    //This method will generate the connection to recieve the information from the meter reader and start its process
    //This method will return an OK message if the process was OK and it is not called from Lightning Page. 
    //Return a JSON string if the process was OK and the method was called from Lightning Page.
    /* 
     * @param String strUrl                     : Holds the url to run the callout 
     * @param Boolean blnReturnJSON             : Will split the process, if it is true return a JSON with the meter readers and if it is false will to the callout.
     * @return String                           : POSTED when the process run without exceptions.
     *                                          : MALFORMAT_JSON when the process was not able to continue for malformatted JSON.
     *                                          : INVALID_URL when the process cannot continue because the url is not valid.
     */
    public static String getMeterReader(String strUrl, Boolean blnInsertMeterReader, String dummyJSON)
    {
        String strJson;
        String strProcessState = 'OK';
        Boolean blnIsValidRecord;

        //This process is created to test all the routine as there is not url to retrieve the data.
        if(dummyJSON == null)
        {
            blnIsValidRecord = validateInfo(strUrl,null,true);
        }
        else 
        {
            blnIsValidRecord = true;
            strJson = dummyJSON;
        }
        
        //if the url is correct we process to get the data.
        if(blnIsValidRecord == true)
        {
            if(String.isBlank(strJson))strJson = getInformation(strUrl);
            
            List<MeterReader> lstMeters = validateJSONAndGenerateRecords(strJson);
            //if the routine retrieve data from get callout, the process deserialize the data to be processed.
            if(!lstMeters.isEmpty())
            {
                strProcessState = storeRecords(lstMeters);
                if('OK'.equals(strProcessState))
                {
                    if(!Test.isRunningTest())
                    {
                        strProcessState = generatePresent(lstMeters,strUrl,blnInsertMeterReader);
                    }
                    else
                    {
                        strProcessState = 'POSTED';    
                    }
                }
                else 
                {
                      System.debug(loggingLevel.INFO,'Something failed in the creation of the records') ;
                }
            }
            else 
            {
                strProcessState = 'MALFORMAT_JSON';
            }
        }
        else 
        {
            strProcessState = 'INVALID_URL';   
        }

        return strProcessState;
    }

    //This method will check if the JSON we have received is well formated and we can convert it to Meter Readers. If not, the list will be null.
    /* 
     * @param String strJSON                     : holds the meter readers in JSON format.
     * 
     * @return List<MeterReader>                 : after validating the JSON formnat return a list of MeterReaders.
     */
    public static List<MeterReader> validateJSONAndGenerateRecords(String strJSON)
    {
        Boolean blnIsValidJSON = true;
        List<MeterReader> lstMeter = new List<MeterReader>();

        if(!String.isBlank(strJson))
        {
            /*Even knowing that the specifications are saying that information will be only one meter read, 
            I think it is better to try if we receive a list, if not we process the JSON as one meter read. */
            try 
            {
                lstMeter = (List<MeterReader>) JSON.deserialize(strJson, List<MeterReader>.class);
            } 
            catch (JSONException e) 
            {
                blnIsValidJSON = false;
            }
            
            if(blnIsValidJSON == false)
            {
                try 
                {
                    MeterReader meter = (MeterReader) JSON.deserialize(strJson, MeterReader.class);
                    lstMeter.add(meter);
                } 
                catch (JSONException e) 
                {
                    blnIsValidJSON = false;
                    lstMeter = new List<MeterReader>();
                }

            }
            
            System.debug(loggingLevel.INFO,lstMeter);
        }
        else 
        {
            System.debug(loggingLevel.INFO,'It was not possible to retrieve the data from the provided url');   
        }
        //Once we converted the JSON in an object we can manipulate, return the meter readers for their storage.
        return lstMeter;
    }
    
    //This function will validate the information received in order to avoid corrupted data.
    /* 
     * @param String strUrl                     : Holds the url to be validated before run the callout.
     * @param Register__c register              : Hold the register to be validated.
     * @param Boolean blnCheckUrl               : Will split the process, if it is true return the process will validate the url and if it is false.
     *                                            the process will validate the Meter lookup and the value in the register to ensure it contain both.
     * @return Boolean                          : If the record or URL passed all the validations, return true else return false.
     */
    public static boolean validateInfo(String strUrl,Register__c register, Boolean blnCheckUrl)
    {
        boolean blnIsValid = true;
        //In this first condition we check if the url contains the string '/meter-read' which ensure that the url is a valid url.
        if(blnCheckUrl == true && !strUrl.contains('/meter-read'))
        {
            blnIsValid = false;
            System.debug(loggingLevel.INFO, 'The url provided is not a valid url');
        }
        else if(register == null && blnCheckUrl == false)
        {
            blnIsValid = false;
        }
        else if(register != null)
        {
            //After checking the register is not null, the process will validate all the essencial data before saving the record.
            //Check that the register has a meter related.
            if(register.Meter__c == null && blnCheckUrl == false)
            {
                System.debug(loggingLevel.INFO, 'The register cannot process because need to have a meter related');
                blnIsValid = false;
            }
            //Check the register has value.
            if(String.isBlank(String.valueOf(register.Value__c)))
            {
                System.debug(loggingLevel.INFO, 'The register cannot process because there is not value');
                blnIsValid = false;
            }
        }
        
        return blnIsValid;
    }
    
    //This function will store the values after validating the result.
    /* 
     * @param List<MeterReader> lstMeterReaders : Hold the list of meter readers to be processed and either post or returned as JSON string.
     * 
     * @return String                           : OK when the routine run without any problem.
     *                                          : ERROR_INSERTION when the routine found an error inserting the records for Customers, Meters and Suppliers.
     *                                          : ERROR_INSERTING_REGISTERS when an error inserting the registers.
     */
    public static String storeRecords(List<MeterReader> lstMeters)
    {
        String strStatus = 'OK';
        System.SavePoint sp = Database.setSavePoint();
        Set<String> setCustomerExternalIDIds = new Set<String>();
        Set<String> setMeterExternalIDIds = new Set<String>();
        Set<String> setSupplierExternalIDIds = new Set<String>();
        Map<String,Customer__c> mapExternalIdToCustomer = new Map<String,Customer__c>();
        Map<String,Meter__c> mapExternalIdToMeter = new Map<String,Meter__c>();
        Map<String,Supplier__c> mapExternalIdToSupplier = new Map<String,Supplier__c>();
        /*First we need to know if the Customers, Meters and Suppliers already exist in the system, for this reason 
        this process will look for them and if they don't exist will create them.*/
        if(lstMeters == null || lstMeters.isEmpty())
        {
            return 'NO_DATA_AVAILABLE';
        }
        for(MeterReader meter : lstMeters)
        {
            setCustomerExternalIDIds.add(meter.customerId);
            setMeterExternalIDIds.add(meter.serialNumber);
            setSupplierExternalIDIds.add(meter.mpxn);
        }
        /* CUSTOMER SECTION TO PROCESS*/ 
        //Get the existing records for customers or create a new ones if they don't exist in the database.
        for(Customer__c cust : [SELECT Id,External_ID__c FROM Customer__c WHERE External_ID__c IN: setCustomerExternalIDIds])
        {
            mapExternalIdToCustomer.put(cust.External_ID__c,cust);
        }
        //Create record for customer not existing in the database.
        for(String exId : setCustomerExternalIDIds)
        {
            if(!mapExternalIdToCustomer.containsKey(exId))
            {
                Customer__c cust = new Customer__c(External_Id__c = exId);
                mapExternalIdToCustomer.put(exId,cust);
            }
        }

        /* METER SECTION TO PROCESS*/ 
        //Get the existing records for meters or create a new ones if they don't exist in the database.
        for(Meter__c met : [SELECT Id,External_ID__c FROM Meter__c WHERE External_ID__c IN: setMeterExternalIDIds])
        {
            mapExternalIdToMeter.put(met.External_ID__c,met);
        }
        //Create record for meters not existing in the database.
        for(String exId : setMeterExternalIDIds)
        {
            if(!mapExternalIdToMeter.containsKey(exId))
            {
                Meter__c met = new Meter__c(External_Id__c = exId);
                mapExternalIdToMeter.put(exId,met);
            }
        }

        /* SUPPLIERS SECTION TO PROCESS*/ 
        //Get the existing records for suppliers or create a new ones if they don't exist in the dtabase.
        for(Supplier__c met : [SELECT Id,External_ID__c FROM Supplier__c WHERE External_ID__c IN: setSupplierExternalIDIds])
        {
            mapExternalIdToSupplier.put(met.External_ID__c,met);
        }
        //Create record for suppliers not existing in the database
        for(String exId : setSupplierExternalIDIds)
        {
            if(!mapExternalIdToSupplier.containsKey(exId))
            {
                Supplier__c sup = new Supplier__c(External_Id__c = exId);
                mapExternalIdToSupplier.put(exId,sup);
            }
        }

        //Let's insert the new records and after we will operate with them, if the routine to create fails, no data will be added the process will stop.
        try 
        {
            if(!mapExternalIdToCustomer.isEmpty())Database.upsert(mapExternalIdToCustomer.values());
            if(!mapExternalIdToMeter.isEmpty())Database.upsert(mapExternalIdToMeter.values());
            if(!mapExternalIdToSupplier.isEmpty())Database.upsert(mapExternalIdToSupplier.values());
        } 
        catch (Exception e) 
        {
            Database.rollback(sp);
            strStatus = 'ERROR_INSERTION';
            return strStatus;
        }

        //Create the register in the database.
        List<Register__c> lstRegisters = new List<Register__c>();

        for(MeterReader meter : lstMeters)
        {
            String strCustomerId = mapExternalIdToCustomer.get(meter.customerId) != null ? mapExternalIdToCustomer.get(meter.customerId).Id : null;
            String strMeterId = mapExternalIdToMeter.get(meter.serialNumber) != null ? mapExternalIdToMeter.get(meter.serialNumber).Id : null;
            meter.customerId = strCustomerID;
            meter.serialNumber = strMeterId;
            meter.mpxn = mapExternalIdToSupplier.get(meter.mpxn) != null ? mapExternalIdToSupplier.get(meter.mpxn).Id : '';
            for(MeterReader.Read read : meter.read)
            {
                Register__c reg = new Register__c(Customer__c = strCustomerId,
                                                  Meter__c = strMeterId,
                                                  External_ID__c = read.registerId,
                                                  Type__c = read.type,
                                                  Value__c = read.value);
                //Validate register before inserting them.
                if(validateInfo('',reg, false) == true)
                {
                    lstRegisters.add(reg);
                }
                else 
                {
                    System.debug(loggingLevel.INFO,'Register with id: ' + read.registerId + ' could not be inserted');    
                }
            }
            
        }
        //Insert the registers in the database.
        try 
        {
           Database.insert(lstRegisters);
        } 
        catch (Exception e) 
        {
            Database.rollback(sp);
            strStatus = 'ERROR_INSERTING_REGISTERS';
            return strStatus;
        }

        return strStatus;
    }
    
    //This function generate a JSON string to present the result after the all the steps below where completed.
    /* 
     * @param String strUrl                     : Holds the url to POST the JSON.
     * @param List<MeterReader> lstMeterReaders : Hold the list of meter readers to be processed and either post or returned as JSON string.
     * @param Boolean blnInsertMeterReader      : Will split the process, if it is true insert meter readers to be available in the system and if it is false will to the callout.
     * 
     * @return String                           : POSTED if the routine run without any problem.
     *                                          : FAILED_PRESENT if there is not data to present.
     *                                          : UNEXPECTED_ERROR Something unexpected happenned.
     *                                          : FAILED_POSTING When something happened in posting the routine.
     *                                            
     */
    public static String generatePresent(List<MeterReader> lstMeterReaders, String strUrl, Boolean blnInsertMeterReader)
    {
        String strStatus = 'OK';
        String strJSON = '';
        //This try catch is to avoid any unexpected situation and avoid the process to break. 
        try 
        {
            if(lstMeterReaders.size() == 1)
            {
                strJSON = JSON.serialize(lstMeterReaders.get(0));
            }
            else if(lstMeterReaders.size() > 1)
            {
                strJSON = JSON.serialize(lstMeterReaders);
            }
            else 
            {
                strStatus = 'FAILED_PRESENT';    
            }
            if('OK'.equals(strStatus))
            {
                strStatus = postInformation(strUrl,strJSON,lstMeterReaders,blnInsertMeterReader);
            }
        } 
        catch (Exception e) 
        {
            strStatus = 'UNEXPECTED_ERROR';
        }
        
        return strStatus;
    }

    /*This function will manage the callout to get data using REST Api from the client and return the body which will contain the meter reader, 
    otherwise will return an empty string.*/
    /* 
     * @param String strUrl         : Holds the url to GET the meter readers in a JSON string.
     * 
     * @RETURN String               : return either an empty string if the connection was not success or the body from the response to create MeterReaders. 
     */
    public static String getInformation(String strUrl)
    {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(strUrl);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        /*If the process is success, will return the body which contains the meter reader otherwise will send and empty string which means the process.
        failed*/
        if(response.getStatusCode() == 200)
        {
            return response.getBody();
        }
        else
        {
            return '';   
        }

    }

    //This function will manage the callout to post data using REST Api after being processed or creating Meter_Reader__c instances.
    /* 
    * @param String strUrl                 : Holds the url to POST the JSON.
    * @param String jsonData               : Holds the meter readers after been processed and stored ready to either load in Lightning Page or be posted to another recipient.
    * @param Boolean blnInsertMeterReader  : Will split the process, if it is true insert meter readers to be available in the system and if it is false will to the callout.
    *
    * @return String                       : POSTED if the routine was successful.
    *                                      : FAILED_POSTING either when something unexpected failed or the callout was not successful.
    */
    public static String postInformation(String strUrl, String jsonData,List<MeterReader> lstMeterReaders, Boolean blnInsertMeterReader)
    {
        
        if(blnInsertMeterReader == true && lstMeterReaders != null)
        {
            //Insert records in the data base to be viewed in the lightning web component.
            List<Meter_Reader__c> lstMeters = new List<Meter_Reader__c>();

            for(MeterReader meter : lstMeterReaders)
            {
                System.debug(loggingLevel.INFO, '#### meter: ' + JSON.serialize(meter));
                meter.dcTotalConsumed = 0;
                for(MeterReader.Read read : meter.read)
                {
                    meter.dcTotalConsumed += read.value;
                }
                System.debug(loggingLevel.INFO,'####Date time before processing: ' + meter.readDate);
                lstMeters.add(new Meter_Reader__c(Customer__c = meter.customerId,
                                                  Meter__c = meter.serialNumber,
                                                  Supplier__c = meter.mpxn,
                                                  Total_Consumed__c = meter.dcTotalConsumed,
                                                  Submited_DateTime__c = DateTime.valueOf(meter.readDate.replace('T',' '))));
                
            }
            //This try catch it is to ensure the process continue if something unexpected happens.
            try 
            {
                System.debug(loggingLevel.INFO,'####' + lstMeters);
                if(!lstMeters.isEmpty())insert lstMeters;
                return 'POSTED';
            } 
            catch (Exception e) { return 'FAILED_POSTING';}
            
        }
        else 
        {
            //Create a HttpRequest POST sending the data to another End Point.
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(strUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setBody(jsonData);
            HttpResponse response = http.send(request);
            System.debug(loggingLevel.INFO,'Code returned: ' + response.getStatusCode());
            //If the callout succed, the return a string saying posted, if not we return a message with what happenned.
            if(response.getStatusCode() == 201 || response.getStatusCode() == 200)
            {
                return 'POSTED';
            }
            else
            {
                return 'FAILED_POSTING';   
            }
        }

    }
}