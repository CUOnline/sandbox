This is a simple LTI app which allows users to quickly provision their own sandbox courses in Canvas for testing. It has two routes, one for a GET request on the base url, and one for POST. 

The GET request renders the XML configuration for adding the LTI tool to Canvas. The POST request is made by Canvas to the tool when it is launched inside Canvas. At this point the app will use the API to create a new course based on the user's name, and then enroll them in it.

To add the app to Canvas, go to Settings > Apps (tab) > View App configurations from the main account admin page. It is easiest to configure "By URL" or "Paste XML" using the XML config served up by the app itself. The consumer key and shared secret should be from a developer key setup ahead of time in Canvas, and should match those configured for the app in wolf_core.yml. If these do not match, the valid_lti_request? method which is called when receiving a POST request will fail. 

Once the app is successfully added, a "Create Sandbox" button will appear on each user's profile page. Permissions to create a sandbox are limited to Admins and Instructors. 
