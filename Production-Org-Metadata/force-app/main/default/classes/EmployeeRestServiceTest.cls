@IsTest
private class EmployeeRestServiceTest {

	private static void setRestContext(String method, String body) {
		RestRequest request = new RestRequest();
		request.httpMethod = method;
		request.requestUri = '/services/apexrest/employee/';
		if (body != null) {
			request.requestBody = Blob.valueOf(body);
		}
		RestContext.request = request;
		RestContext.response = new RestResponse();
	}

	@IsTest
	static void createEmployee_success() {
		String payload = JSON.serialize(new Map<String, Object>{
			'Employee_Name__c' => 'Test Employee',
			'Employee_Email__c' => 'test.employee@example.com',
			'Joining_Date__c' => '2024-01-15',
			'Salary_CTC__c' => 120000,
			'Active__c' => true
		});

		setRestContext('POST', payload);

		Test.startTest();
		String responseBody = EmployeeRestService.createEmployee();
		Test.stopTest();

		System.assertEquals(201, RestContext.response.statusCode, 'Status should be 201');

		Map<String, Object> response =
			(Map<String, Object>) JSON.deserializeUntyped(responseBody);

		System.assertEquals(true, response.get('success'));
		System.assertNotEquals(null, response.get('recordId'));

		Id employeeId = (Id) response.get('recordId');
		Employee__c createdEmployee = [
			SELECT Id, Employee_Name__c, Employee_Email__c, Joining_Date__c,
				   Salary_CTC__c, Active__c
			FROM Employee__c
			WHERE Id = :employeeId
			LIMIT 1
		];

		System.assertEquals('Test Employee', createdEmployee.Employee_Name__c);
		System.assertEquals('test.employee@example.com', createdEmployee.Employee_Email__c);
		System.assertEquals(Date.newInstance(2024, 1, 15), createdEmployee.Joining_Date__c);
		System.assertEquals(120000, createdEmployee.Salary_CTC__c);
		System.assertEquals(true, createdEmployee.Active__c);
	}

	@IsTest
	static void createEmployee_invalidJson_returnsError() {
		setRestContext('POST', '{ invalid json }');

		Test.startTest();
		String responseBody = EmployeeRestService.createEmployee();
		Test.stopTest();

		System.assertEquals(400, RestContext.response.statusCode, 'Status should be 400');

		Map<String, Object> response =
			(Map<String, Object>) JSON.deserializeUntyped(responseBody);

		System.assertEquals(false, response.get('success'));
		System.assertNotEquals(null, response.get('message'));
	}

	@IsTest
	static void getEmployeeFields_success() {
		setRestContext('GET', null);

		Test.startTest();
		String responseBody = EmployeeRestService.getEmployeeFields();
		Test.stopTest();

		System.assertEquals(200, RestContext.response.statusCode, 'Status should be 200');

		Map<String, Object> response =
			(Map<String, Object>) JSON.deserializeUntyped(responseBody);

		System.assertEquals(true, response.get('success'));

		List<Object> fields = (List<Object>) response.get('fields');
		System.assert(fields.size() > 0, 'Fields list should not be empty');

		Boolean found = false;
		for (Object entry : fields) {
			Map<String, Object> fieldDetails = (Map<String, Object>) entry;
			if (String.valueOf(fieldDetails.get('apiName')) == 'Employee_Name__c') {
				found = true;
				break;
			}
		}

		System.assertEquals(true, found, 'Expected Employee_Name__c in fields list');
	}
}
