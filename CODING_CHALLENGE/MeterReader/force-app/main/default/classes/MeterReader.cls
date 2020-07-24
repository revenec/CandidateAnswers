//Inner class to store and manage the data from the JSON file temporally.
public with sharing class MeterReader 
{
    public String customerId {get;set;}
    public String serialNumber {get;set;}
    public String mpxn {get;set;}
    public List<Read> read;
    public String readDate {get;set;}
    public Decimal dcTotalConsumed {get;set;}

    //Constructor
    public MeterReader(String customerId, String serialNumber, String mpxn,List<Read> lstReadings, String readDate)
    {
        this.customerId = customerId;
        this.serialNumber = serialNumber;
        this.mpxn = mpxn;
        this.readDate = readDate;
        this.read = lstReadings.clone();
    }

    //Class for registers
    public class Read
    {
        public String type;
        public String registerId;
        public Integer value;
    }
}