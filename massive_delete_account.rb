require "google/apis/admin_directory_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

file='file.csv'


OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Delete User massive".freeze
CREDENTIALS_PATH = "credentials.json".freeze

TOKEN_PATH = "token.yaml".freeze
SCOPE =  Google::Apis::AdminDirectoryV1::AUTH_ADMIN_DIRECTORY_USER

def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end
service = Google::Apis::AdminDirectoryV1::DirectoryService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

begin##lendo file e percorrendo array
  count =0 
  counte =0
    File.readlines(file).each { |line|
          email=line.split("\n")[0]
	  puts email
             begin
              resultados = service.list_users(customer:"my_customer",query: email, max_results: 1, order_by:"email" )
              #resultados.users.first.last_login_time.to_date < Date.parse("2021-03-31")
              if(!resultados.users.nil?)then
		#puts "search nulo, e-mail não existe na base"
              if resultados.users.first.suspended? then
                begin
                puts service.delete_user(email)
                count +=1
              rescue
                counte +=1
              end
		end
              end
            end##fim begin verificando se existe e-mail
          }##fim file.readlines each
	rescue Errno::ENOENT
	   p 'file not found'
	rescue ArgumentError
	     p 'file contains unparsable numbers'
	else##else begin
  		puts "else"
end##fim begin criando o objeto membro classe
puts "#{count} e-mails deletados de #{counte} e-mails lidos"
