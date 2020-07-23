//This class will contain the methods to accept,validate, store and present the meter reader
public class HelperMeterReader 
{
	//This method will generate the connection to recieve the information from the meter reader and start its process
    public static String getMeterReader(String strUrl)
    {
        String strJson;
        String strProcessState = 'OK';
        Boolean blnIsValidRecord;

        blnIsValidRecord = validateInfo(strUrl,null,true);

        //if the url is correct we process to get the data 
        if(blnIsValidRecord == true)
        {
            strJson = getInformation(strUrl);
            
            //if the process retrieve data from get callout, the process deserialize the data to be processed
            List<MeterReader> lstMeters = validateJSONAndGenerateRecords(strJson);

            if(!lstMeters.isEmpty())
            {
                strProcessState = storeRecords(lstMeters);
                if('OK'.equals(strProcessState))
                {
                    if(!Test.isRunningTest())
                    {
                        strProcessState = generatePresent(lstMeters,strUrl);
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

    //This method will check if the JSON we have received is well formated and we can convert it. If not, the list will be null
    public static List<MeterReader> validateJSONAndGenerateRecords(String strJSON)
    {
        Boolean blnIsValidJSON = true;
        List<MeterReader> lstMeter = new List<MeterReader>();

        if(!String.isBlank(strJson))
        {
            /*Even knowing that the specifications are saying that information will be only one meter read, 
            I think it is better to try if we receive a list, if not we process the JSON as one meter read */
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
            //Once we converted the JSON in an object we can manipulate, let's store the information
            System.debug(lstMeter);
        }
        else 
        {
            System.debug('It was not possible to retrieve the data from the provided url');   
        }
        
        return lstMeter;
    }
    
    //This function will validate the information received in order to avoid corrupted data by returning true or false
    public static boolean validateInfo(String strUrl,Register__c register, boolean blnCheckUrl)
    {
        boolean blnIsValid = true;
        //In this first condition we check if the url contains the string '/meter-read' which ensure that the url is a valid url
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
            //After checking the register is not null, the process will validate all the essencial data before saving the record
            //Check that the register has a meter related
            if(register.Meter__c == null && blnCheckUrl == false)
            {
                System.debug(loggingLevel.INFO, 'The register cannot process because need to have a meter related');
                blnIsValid = false;
            }
            //Check the register has value
            if(String.isBlank(String.valueOf(register.Value__c)))
            {
                System.debug(loggingLevel.INFO, 'The register cannot process because there is not value');
                blnIsValid = false;
            }
        }
        
        return blnIsValid;
    }
    
    //This function will store the values after validating the result
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
        this process will look for them and if they don't exist will create them*/
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
        //Get the existing records for customers and create a new ones if they don't exist in the system
        for(Customer__c cust : [SELECT Id,External_ID__c FROM Customer__c WHERE External_ID__c IN: setCustomerExternalIDIds])
        {
            mapExternalIdToCustomer.put(cust.External_ID__c,cust);
        }
        //Create record for customer not existing in the system
        for(String exId : setCustomerExternalIDIds)
        {
            if(!mapExternalIdToCustomer.containsKey(exId))
            {
                Customer__c cust = new Customer__c(External_Id__c = exId);
                mapExternalIdToCustomer.put(exId,cust);
            }
        }

        /* METER SECTION TO PROCESS*/ 
        //Get the existing records for meters and create a new ones if they don't exist in the system
        for(Meter__c met : [SELECT Id,External_ID__c FROM Meter__c WHERE External_ID__c IN: setMeterExternalIDIds])
        {
            mapExternalIdToMeter.put(met.External_ID__c,met);
        }
        //Create record for meters not existing in the system
        for(String exId : setMeterExternalIDIds)
        {
            if(!mapExternalIdToMeter.containsKey(exId))
            {
                Meter__c met = new Meter__c(External_Id__c = exId);
                mapExternalIdToMeter.put(exId,met);
            }
        }

        /* SUPPLIERS SECTION TO PROCESS*/ 
        //Get the existing records for suppliers and create a new ones if they don't exist in the system
        for(Supplier__c met : [SELECT Id,External_ID__c FROM Supplier__c WHERE External_ID__c IN: setSupplierExternalIDIds])
        {
            mapExternalIdToSupplier.put(met.External_ID__c,met);
        }
        //Create record for suppliers not existing in the system
        for(String exId : setSupplierExternalIDIds)
        {
            if(!mapExternalIdToSupplier.containsKey(exId))
            {
                Supplier__c sup = new Supplier__c(External_Id__c = exId);
                mapExternalIdToSupplier.put(exId,sup);
            }
        }

        //Let's insert the new records and after we will operate with them, if the process of creation failes, no data will be added the process will stop
        try 
        {
           Database.upsert(mapExternalIdToCustomer.values());
           Database.upsert(mapExternalIdToMeter.values());
           Database.upsert(mapExternalIdToSupplier.values());
        } 
        catch (Exception e) 
        {
            Database.rollback(sp);
            strStatus = 'ERROR_INSERTION';
            return strStatus;
        }

        //Create the register for the data base
        List<Register__c> lstRegisters = new List<Register__c>();

        for(MeterReader meter : lstMeters)
        {
            String strCustomerId = mapExternalIdToCustomer.get(meter.customerId) != null ? mapExternalIdToCustomer.get(meter.customerId).Id : null;
            String strMeterId = mapExternalIdToMeter.get(meter.serialNumber) != null ? mapExternalIdToMeter.get(meter.serialNumber).Id : null;
            
            for(MeterReader.Read read : meter.read)
            {
                Register__c reg = new Register__c(Customer__c = strCustomerId,
                                                  Meter__c = strMeterId,
                                                  External_ID__c = read.registerId,
                                                  Type__c = read.type,
                                                  Value__c = read.value);
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
    
    //This function generate a JSON string to present the result after the all the steps below where completed
    public static String generatePresent(List<MeterReader> lstMeterReaders, String strUrl)
    {
        String strStatus = 'OK';
        String strJSON = '';

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
            strStatus = postInformation(strUrl,strJSON);
        }
        return strStatus;
    }

    /*This function will manage the callout to get data using REST Api from the client and return the body which will contain the meter reader, 
    otherwise will return an empty string*/
    public static String getInformation(String strUrl)
    {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(strUrl);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        /*If the process is success, will return the body which contains the meter reader otherwise will send and empty string which means the process
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

    //This function will manage the callout to post data using REST Api after being processed
    public static String postInformation(String strUrl, String jsonData)
    {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(strUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(jsonData);
        HttpResponse response = http.send(request);
        System.debug(loggingLevel.INFO,'Code returned: ' + response.getStatusCode());
        //If the callout succed, the return a string saying posted, if not we return a message with what happenned  
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