public with sharing class MeterReader 
{
    public String customerId;
    public String serialNumber;
    public String mpxn;
    public List<Read> read;
    public String readDate;

    public MeterReader(String customerId, String serialNumber, String mpxn,List<Read> lstReadings, String readDate) 
    {
        this.customerId = customerId;
        this.serialNumber = serialNumber;
        this.mpxn = mpxn;
        this.readDate = readDate;
        this.read = lstReadings.clone();
    }

    public class Read
    {
        public String type;
        public String registerId;
        public Integer value;
    }
}