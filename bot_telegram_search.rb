require 'telegram/bot'
#require 'net/http/persistent'

token = 'TOKEN TELEGRAM'
ler_texto = false ###usado para fazer com que o bot espere o usuário digitar algo
ler_cpf = false ###usado para fazer com que o bot espere o usuário digitar um cpf
usuarios = ""

confiaveis = [, ] ###confiáveis ,reliable
### fim variáveis
##### Conceitos/Concepts ######
#CPF = código funcionário / employee code 
#CPF = externalID/employee code 
#
##### Conceitos/Concepts ######

###inicio metodos
####iniciando conexão com google api

require "google/apis/admin_directory_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Directory API Ruby Quickstart".freeze
CREDENTIALS_PATH = "credentials.json".freeze

TOKEN_PATH = "token.yaml".freeze
SCOPE = [Google::Apis::AdminDirectoryV1::AUTH_ADMIN_DIRECTORY_GROUP_MEMBER, Google::Apis::AdminDirectoryV1::AUTH_ADMIN_DIRECTORY_USER]

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

####fim conexão com google api, porem fica a variável service disponível a ser utilizada nos metodos abaixo

##separador de consultar por usuário(<Google::Apis::AdminDirectoryV1::User:)
#comando para verificar status do e-mail por nome/e-mail/e-mails pessoal
def pesquisaMail(texto)## inicio pesquisaMail
	service = Google::Apis::AdminDirectoryV1::DirectoryService.new
	service.client_options.application_name = APPLICATION_NAME
	service.authorization = authorize
	usuarios = "**Dados encontrados**:\n\n"
	cont = 0
	resultados = service.list_users(customer:"my_customer",query: "#{texto}", max_results: 10, order_by:"email" )
	if(!resultados.nil?) then
	if(!resultados.users.nil?)then
		resultados.users.each { 
			|user| usuarios = usuarios + 
												"\n\nNome: #{user.name.full_name}\n CPF:  #{user.external_ids[0].values[0]}\n"+
			 									"E-mail: #{user.primary_email}\n E-mail Pessoal: #{user.recovery_email}\n"+
			 									"Unidade Organizacional: #{user.org_unit_path}\n Status: "+(user.suspended == false ? "Ativo": "Inativo") ; 
			 									cont +=1 
		}##fim resultados
		usuarios = usuarios + "\n\nTotal de #{cont} resultados."
	else
		usuarios = "Nenhum usuário encontrado com o texto indicado."
	end
	else
		usuarios = "Nenhum usuário encontrado com o texto indicado."

	end##fim if(!resultados.nil?) then
return usuarios 
end##fim pesquisaMail

#comando consulta cpf
def pesquisaMailCPF(cpf)
service = Google::Apis::AdminDirectoryV1::DirectoryService.new
	service.client_options.application_name = APPLICATION_NAME
	service.authorization = authorize
	usuarios = "**Dados encontrados**:\n\n"
	cont = 0

#resultados = service.list_users(customer:"my_customer",query: "#{texto}", max_results: 10, order_by:"email" )
resultados = service.list_users(customer:"my_customer",query: "externalId:#{cpf}", max_results: 10, order_by:"email")	
	if(!resultados.nil?) then
	if(!resultados.users.nil?)then
		resultados.users.each { 
			|user| usuarios = usuarios + 
												"\n\nNome: #{user.name.full_name}\n CPF:  #{user.external_ids[0].values[0]}\n"+
			 									"E-mail: #{user.primary_email}\n E-mail Pessoal: #{user.recovery_email}\n"+
			 									"Unidade Organizacional: #{user.org_unit_path}\n Status: "+(user.suspended == false ? "Ativo": "Inativo") ;
			 									cont +=1 
		}##fim resultados
		usuarios = usuarios + "\n\nTotal de #{cont} resultados."
	else
		usuarios = "Nenhum usuário encontrado com o cpf indicado."
	end
	else
		usuarios = "Nenhum usuário encontrado com o cpf indicado."
	end##fim if(!resultados.nil?) then
return usuarios 
end##fim def pesquisaMailCPF(cpf)

#consulta se e-mail faz parte de grupo



##resultados.users.first.external_ids[0].values[0]    -----  pegando 
###fim metodos


#BOT rodando
#inicio LISTEN
Telegram::Bot::Client.run(token) do |bot|###inicio listen
  #config.adapter = :net_http_persistent
  #bot.api.send_message(chat_id: '132560166' , text: "/start", parse_mode: 'Markdown')
  bot.listen do |message|
  	#definindo teclado padrão
   	teclado =
          Telegram::Bot::Types::ReplyKeyboardMarkup
              .new(keyboard: [%w(CPF), %w(E-MAIL Nome)], one_time_keyboard: false)
      # See more: https://core.telegram.org/bots/api#replykeyboardmarkup

    ativo = (message.chat.id)##pegando chat_id para comparar
         
    if (!ativo.nil? && ler_texto==false && ler_cpf==false) then###verificando se tem permissao
    	case message.text
    			when '/start'
    				msginicio = "Olá #{message.from.first_name}.\bTecle na opção desejada "
	          bot.api.send_message(chat_id: message.chat.id, text: msginicio, reply_markup: teclado)
	        when 'Início','inicio'
	          msginicio = "Olá #{message.from.first_name}.\bTecle na opção desejada "
	          bot.api.send_message(chat_id: message.chat.id, text: msginicio, reply_markup: teclado)
	        when "Nome","nome", "E-MAIL","e-mail","email"
	        	bot.api.send_message(chat_id: message.chat.id, text: "**Digite o termo para pesquisa**", reply_markup: teclado, parse_mode: 'Markdown')
	        	ler_texto = true
	        when "CPF","cpf"
	        	bot.api.send_message(chat_id: message.chat.id, text: "Digite o cpf, apenas números:", reply_markup: teclado, parse_mode: 'Markdown')
	        	ler_cpf = true
	    end###fim case message.text
	  elsif (!message.text.nil? && message.text != "/start" && ler_texto==true)then
	  		ler_texto = false
	  	if(message.text != ["CPF","E-MAIL","Nome","Início"])
	  		retorno = pesquisaMail(message.text)
	    	bot.api.send_message(chat_id: message.chat.id, text: retorno, reply_markup: teclado,parse_mode: 'Markdown')
	    end
	  elsif (!message.text.nil? && message.text != "/start" && ler_cpf==true)then
	  		ler_cpf = false
	  	if(message.text != ["CPF","E-MAIL","Nome","Início"] )
	  		retorno = pesquisaMailCPF(message.text)
				bot.api.send_message(chat_id: message.chat.id, text: retorno, reply_markup: teclado, parse_mode: 'Markdown')
			end
		else
			mensage_permissao="Olá #{message.from.first_name}.\bSeu chat_id: #{message.chat.id} "
			bot.api.send_message(chat_id: message.chat.id, text: mensage_permissao)
  	end ##fim if(ativo)then
  end ###fim bot.listen
end ###fim Telegram::



#fim
