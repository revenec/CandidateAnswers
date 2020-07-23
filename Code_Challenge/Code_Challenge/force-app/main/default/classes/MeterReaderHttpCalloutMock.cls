@isTest
global class MeterReaderHttpCalloutMock  implements HttpCalloutMock{
    
    public static String jsonTest = '{ ' +
                                    '"customerId": "identifier123",' + 
                                    '"serialNumber": "27263927192",' + 
                                    '"mpxn": "14582749",' +
                                    '"read": [' +
                                        '{"type": "ANYTIME", "registerId": "387373", "value": "2729"},' +
                                        '{"type": "NIGHT", "registerId": "387373", "value": "2892"}' +
                                    '],' + 
                                    '"readDate": "2017-11-20T16:19:48+00:00Z"' + 
                                    '}';

    //Implement the interface method
    global HTTPResponse respond (HttpRequest request)
    {
        HttpResponse response = new HttpResponse();
        //Here we defind in the header the type of data this HttpResponse will contain in the body
        response.setHeader('Content-Type', 'application/json');
        response.setBody(jsonTest);
        if(request.getEndpoint().contains('300'))
        {
            response.setStatusCode(300);
        }
        else 
        {
            response.setStatusCode(200);
        }

        return response;
    }
}
