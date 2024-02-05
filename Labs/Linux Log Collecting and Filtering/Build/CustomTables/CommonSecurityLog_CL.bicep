param workspaceName string

var CommonSecurityLog_CL_Name = 'CommonSecurityLog_CL'

resource Workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: workspaceName
}

resource CommonSecurityLog_CL_Table 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: Workspace
  name: CommonSecurityLog_CL_Name
  properties: {
    totalRetentionInDays: -1
    plan: 'Analytics'
    schema: {
      name: CommonSecurityLog_CL_Name
      columns: [
        {
          name: 'TimeGenerated'
          type: 'datetime'
          description: 'Event collection time in UTC.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceVendor'
          type: 'string'
          description: 'String that together with device product and version definitions, uniquely identifies the type of sending device.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceProduct'
          type: 'string'
          description: 'String that together with device product and version definitions, uniquely identifies the type of sending device.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceVersion'
          type: 'string'
          description: 'String that together with device product and version definitions, uniquely identifies the type of sending device.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceEventClassID'
          type: 'string'
          description: 'String or integer that serves as a unique identifier per event type.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'Activity'
          type: 'string'
          description: 'A string that represents a human-readable and understandable description of the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'LogSeverity'
          type: 'string'
          description: 'A string or integer that describes the importance of the event. Valid string values:Unknown,Low,Medium,High,Very-High Valid integer values are:0-3= Low,4-6= Medium,7-8= High,9-10= Very-High.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OriginalLogSeverity'
          type: 'string'
          description: 'A non-mapped version of LogSeverity. For example: Warning/Critical/Info insted of the normilized Low/Medium/High in the LogSeverity Field'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'AdditionalExtensions'
          type: 'string'
          description: 'A placeholder for additional fields. Fields are logged as key-value pairs.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceAction'
          type: 'string'
          description: 'The action mentioned in the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ApplicationProtocol'
          type: 'string'
          description: 'The protocol used in the application, such as HTTP, HTTPS, SSHv2, Telnet, POP, IMPA, IMAPS, and so on.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'EventCount'
          type: 'int'
          description: 'A count associated with the event, showing how many times the same event was observed.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationDnsDomain'
          type: 'string'
          description: 'The DNS part of the fully-qualified domain name (FQDN).'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationServiceName'
          type: 'string'
          description: 'The service that is targeted by the event. For example:sshd.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationTranslatedAddress'
          type: 'string'
          description: 'Identifies the translated destination referred to by the event in an IP network, as an IPv4 IP address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationTranslatedPort'
          type: 'int'
          description: 'Port after translation, such as a firewall Valid port numbers:0-65535.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'CommunicationDirection'
          type: 'string'
          description: 'Any information about the direction the observed communication has taken. Valid values:0= Inbound, 1= Outbound.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceDnsDomain'
          type: 'string'
          description: 'The DNS domain part of the full qualified domain name (FQDN).'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceExternalID'
          type: 'string'
          description: 'A name that uniquely identifies the device generating the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceFacility'
          type: 'string'
          description: 'The facility generating the event. For example: auth or local1.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceInboundInterface'
          type: 'string'
          description: 'The interface on which the packet or data entered the device. For example: ethernet1/2.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceNtDomain'
          type: 'string'
          description: 'The Windows domain of the device address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceOutboundInterface'
          type: 'string'
          description: 'Interface on which the packet or data left the device.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DevicePayloadId'
          type: 'string'
          description: 'Unique identifier for the payload associated with the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ProcessName'
          type: 'string'
          description: 'Process name associated with the event. For example: in UNIX, the process generating the syslog entry.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceTranslatedAddress'
          type: 'string'
          description: 'Identifies the translated device address that the event refers to, in an IP network. The format is an Ipv4 address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationHostName'
          type: 'string'
          description: 'The destination that the event refers to in an IP network. The format should be an FQDN associated with the destination node, when a node is available. For example:host.domain.comorhost.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationMACAddress'
          type: 'string'
          description: 'The destination MAC address (FQDN).'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationNTDomain'
          type: 'string'
          description: 'The Windows domain name of the destination address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationProcessId'
          type: 'int'
          description: 'The ID of the destination process associated with the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationUserPrivileges'
          type: 'string'
          description: 'Defines the destination use\'s privileges. Valid values:Admninistrator,User,Guest.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationProcessName'
          type: 'string'
          description: 'The name of the event’s destination process, such astelnetdorsshd.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationPort'
          type: 'int'
          description: 'Destination port. Valid values:0-65535.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationIP'
          type: 'string'
          description: 'The destination IpV4 address that the event refers to in an IP network.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceTimeZone'
          type: 'string'
          description: 'Timezone of the device generating the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationUserID'
          type: 'string'
          description: 'Identifies the destination user by ID. For example: in Unix, the root user is generally associated with the user ID 0.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DestinationUserName'
          type: 'string'
          description: 'Identifies the destination user by name.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceAddress'
          type: 'string'
          description: 'The IPv4 address of the device generating the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceName'
          type: 'string'
          description: 'The FQDN associated with the device node, when a node is available. For example:host.domain.comorhost.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceMacAddress'
          type: 'string'
          description: 'The MAC address of the device generating the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ProcessID'
          type: 'int'
          description: 'Defines the ID of the process on the device generating the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'EndTime'
          type: 'datetime'
          description: 'The time at which the activity related to the event ended.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ExternalID'
          type: 'int'
          description: 'Soon to be a deprecated field. Will be replaced by ExtID.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ExtID'
          type: 'string'
          description: 'An ID used by the originating device (will replace legacy ExternalID). Typically, these values have increasing values that are each associated with an event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileCreateTime'
          type: 'string'
          description: 'Time when the file was created.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileHash'
          type: 'string'
          description: 'Hash of a file.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileID'
          type: 'string'
          description: 'An ID associated with a file, such as the inode.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileModificationTime'
          type: 'string'
          description: 'Time when the file was last modified.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FilePath'
          type: 'string'
          description: 'Full path to the file, including the filename. For example:C:\\ProgramFiles\\WindowsNT\\Accessories\\wordpad.exeor/usr/bin/zip.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FilePermission'
          type: 'string'
          description: 'The file\'s permissions. For example: \'2,1,1\'.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileType'
          type: 'string'
          description: 'File type, such as pipe, socket, and so on.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileName'
          type: 'string'
          description: 'The file\'s name, without the path.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FileSize'
          type: 'int'
          description: 'The size of the file in bytes.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ReceivedBytes'
          type: 'long'
          description: 'Number of bytes transferred inbound.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'Message'
          type: 'string'
          description: 'A message that gives more details about the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileCreateTime'
          type: 'string'
          description: 'Time when the old file was created.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileHash'
          type: 'string'
          description: 'Hash of the old file.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileID'
          type: 'string'
          description: 'And ID associated with the old file, such as the inode.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileModificationTime'
          type: 'string'
          description: 'Time when the old file was last modified.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileName'
          type: 'string'
          description: 'Name of the old file.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFilePath'
          type: 'string'
          description: 'Full path to the old file, including the filename. For example:C:\\ProgramFiles\\WindowsNT\\Accessories\\wordpad.exeor/usr/bin/zip.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFilePermission'
          type: 'string'
          description: 'Permissions of the old file. For example: \'2,1,1\'.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileSize'
          type: 'int'
          description: 'The size of the old file in bytes.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'OldFileType'
          type: 'string'
          description: 'File type of the old file, such as a pipe, socket, and so on.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SentBytes'
          type: 'long'
          description: 'Number of bytes transferred outbound.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'EventOutcome'
          type: 'string'
          description: 'Displays the outcome, usually as ‘success’ or ‘failure’.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'Protocol'
          type: 'string'
          description: 'Transport protocol that identifies the Layer-4 protocol used. Possible values include protocol names, such asTCPorUDP.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'Reason'
          type: 'string'
          description: 'The reason an audit event was generated. For example \'bad password\' or \'unknown user\'. This could also be an error or return code. Example: \'0x1234\'.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RequestURL'
          type: 'string'
          description: 'The URL accessed for an HTTP request, including the protocol. For example:http://www/secure.com.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RequestClientApplication'
          type: 'string'
          description: 'The user agent associated with the request.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RequestContext'
          type: 'string'
          description: 'Describes the content from which the request originated, such as the HTTP Referrer.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RequestCookies'
          type: 'string'
          description: 'Cookies associated with the request.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RequestMethod'
          type: 'string'
          description: 'The method used to access a URL. Valid values include methods such asPOST,GET, and so on.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ReceiptTime'
          type: 'string'
          description: 'The time at which the event related to the activity was received. Different then the \'Timegenerated\' field, which is when the event was recieved in the log collector machine.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceHostName'
          type: 'string'
          description: 'Identifies the source that event refers to in an IP network. Format should be a fully qualified domain name (DQDN) associated with the source node, when a node is available. For example:hostorhost.domain.com.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceMACAddress'
          type: 'string'
          description: 'Source MAC address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceNTDomain'
          type: 'string'
          description: 'The Windows domain name for the source address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceDnsDomain'
          type: 'string'
          description: 'The DNS domain part of the complete FQDN.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceServiceName'
          type: 'string'
          description: 'The service responsible for generating the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceTranslatedAddress'
          type: 'string'
          description: 'Identifies the translated source that the event refers to in an IP network.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceTranslatedPort'
          type: 'int'
          description: 'Source port after translation, such as a firewall. Valid port numbers are0-65535.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceProcessId'
          type: 'int'
          description: 'The ID of the source process associated with the event.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceUserPrivileges'
          type: 'string'
          description: 'The source user\'s privileges. Valid values include:Administrator,User,Guest.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceProcessName'
          type: 'string'
          description: 'The name of the event\'s source process.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourcePort'
          type: 'int'
          description: 'The source port number. Valid port numbers are0-65535.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceIP'
          type: 'string'
          description: 'The source that an event refers to in an IP network, as an IPv4 address.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'StartTime'
          type: 'datetime'
          description: 'The time when the activity that the event refers to started.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceUserID'
          type: 'string'
          description: 'Identifies the source user by ID.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceUserName'
          type: 'string'
          description: 'Identifies the source user by name. Email addresses are also mapped into the UserName fields. The sender is a candidate to put into this field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'EventType'
          type: 'int'
          description: 'Event type. Value values include: 0: base event, 1: aggregated, 2: correlation event, 3: action event. Note: This event can be omitted for base events.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceEventCategory'
          type: 'string'
          description: 'Represents the category assigned by the originating device. Devices often use their own categorization schema to classify event. Example: \'/Monitor/Disk/Read\'.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address1'
          type: 'string'
          description: 'One of four IPv6 address fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address1Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address2'
          type: 'string'
          description: 'One of four IPv6 address fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address2Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address3'
          type: 'string'
          description: 'One of four IPv6 address fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address3Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address4'
          type: 'string'
          description: 'One of four IPv6 address fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomIPv6Address4Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint1'
          type: 'real'
          description: 'One of four floating point fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint1Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint2'
          type: 'real'
          description: 'One of four floating point fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint2Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint3'
          type: 'real'
          description: 'One of four floating point fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint3Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint4'
          type: 'real'
          description: 'One of four floating point fields available to map fields that do not apply to any other in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomFloatingPoint4Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomNumber1'
          type: 'int'
          description: 'Soon to be a deprecated field. Will be replaced by FieldDeviceCustomNumber1.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FieldDeviceCustomNumber1'
          type: 'long'
          description: 'One of three number fields available to map fields that do not apply to any other in this dictionary (will replace legacy DeviceCustomNumber1). Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomNumber1Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomNumber2'
          type: 'int'
          description: 'Soon to be a deprecated field. Will be replaced by FieldDeviceCustomNumber2.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FieldDeviceCustomNumber2'
          type: 'long'
          description: 'One of three number fields available to map fields that do not apply to any other in this dictionary (will replace legacy DeviceCustomNumber2). Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomNumber2Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomNumber3'
          type: 'int'
          description: 'Soon to be a deprecated field. Will be replaced by FieldDeviceCustomNumber3.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FieldDeviceCustomNumber3'
          type: 'long'
          description: 'One of three number fields available to map fields that do not apply to any other in this dictionary (will replace legacy DeviceCustomNumber3). Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomNumber3Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString1'
          type: 'string'
          description: 'One of six strings available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString1Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString2'
          type: 'string'
          description: 'One of six strings available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString2Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString3'
          type: 'string'
          description: 'One of six strings available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString3Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString4'
          type: 'string'
          description: 'One of six strings available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString4Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString5'
          type: 'string'
          description: 'One of six strings available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString5Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString6'
          type: 'string'
          description: 'One of six strings available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomString6Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomDate1'
          type: 'string'
          description: 'One of two timestamp fields available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomDate1Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomDate2'
          type: 'string'
          description: 'One of two timestamp fields available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'DeviceCustomDate2Label'
          type: 'string'
          description: 'All custom fields have a corresponding label field. Each of these fields is a string and describes the purpose of the custom field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexDate1'
          type: 'string'
          description: 'A timestamp field available to map a timestamp that does not apply to any other defined timestamp field in this dictionary. Use all flex fields sparingly and seek a more specific, dictionary supplied field when possible. These fields are typically reserved for customer use and should not be set by vendors unless necessary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexDate1Label'
          type: 'string'
          description: 'The label field is a string and describes the purpose of the flex field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexNumber1'
          type: 'int'
          description: 'Number fields available to map Int data that does not apply to any other field in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexNumber1Label'
          type: 'string'
          description: 'The label that describes the value in FlexNumber1'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexNumber2'
          type: 'int'
          description: 'Number fields available to map Int data that does not apply to any other field in this dictionary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexNumber2Label'
          type: 'string'
          description: 'The label that describes the value in FlexNumber2'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexString1'
          type: 'string'
          description: 'One of four floating point fields available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible. These fields are typically reserved for customer use and should not be set by vendors unless necessary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexString1Label'
          type: 'string'
          description: 'The label field is a string and describes the purpose of the flex field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexString2'
          type: 'string'
          description: 'One of four floating point fields available to map fields that do not apply to any other in this dictionary. Use sparingly and seek a more specific, dictionary supplied field when possible. These fields are typically reserved for customer use and should not be set by vendors unless necessary.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'FlexString2Label'
          type: 'string'
          description: 'The label field is a string and describes the purpose of the flex field.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RemoteIP'
          type: 'string'
          description: 'The remote IP address, derived from the event\'s direction value, if possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'RemotePort'
          type: 'string'
          description: 'The remote port, derived from the event\'s direction value, if possible.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'MaliciousIP'
          type: 'string'
          description: 'If one of the IP in the message was correlate with the current TI feed we have it will show up here.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ThreatSeverity'
          type: 'int'
          description: 'The threat severity of the MaliciousIP according to our TI feed at the time of the record ingestion.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'IndicatorThreatType'
          type: 'string'
          description: 'The threat type of the MaliciousIP according to our TI feed.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ThreatDescription'
          type: 'string'
          description: 'The threat description of the MaliciousIP according to our TI feed.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ThreatConfidence'
          type: 'string'
          description: 'The threat confidence of the MaliciousIP according to our TI feed.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'ReportReferenceLink'
          type: 'string'
          description: 'Link to the report of the TI feed.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'MaliciousIPLongitude'
          type: 'real'
          description: 'The Longitude of the MaliciousIP according to the GEO information at the time of the record ingestion.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'MaliciousIPLatitude'
          type: 'real'
          description: 'The Latitude of the MaliciousIP according to the GEO information at the time of the record ingestion.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'MaliciousIPCountry'
          type: 'string'
          description: 'The country of the MaliciousIP according to the GEO information at the time of the record ingestion.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'Computer'
          type: 'string'
          description: 'Host, from Syslog.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SourceSystem'
          type: 'string'
          description: 'Hard coded- \'OpsManager\'.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'SimplifiedDeviceAction'
          type: 'string'
          description: 'A mapped version of DeviceAction, such as Denied > Deny.'
          isDefaultDisplay: true
          isHidden: false
        }
        {
          name: 'CollectorHostName'
          type: 'string'
          description: 'The hostname of the collector machine running the agent.'
          isDefaultDisplay: true
          isHidden: false
        }
      ]
    }
    retentionInDays: -1
    }
}

