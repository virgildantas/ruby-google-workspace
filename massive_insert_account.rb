require "google/apis/admin_directory_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require 'differ'


####PREENCHER COM DADOS CORRETOS
ticketNumber='TickerNumer'
file='file.csv'
groupKey="group_created@yourdomain.com"
#
fileErro="erros_importacao-#{ticketNumber}.txt"
fileCorrecao="corrigidos_importacao-#{ticketNumber}.txt"
#

#
emailoriginal=""
emailcorrigido=""
emailserrados="corrigido ,original , erro apresentado\n"
mensagemFinal=""

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Directory API Ruby Quickstart".freeze
CREDENTIALS_PATH = "/opt/googleAPI/credentials.json".freeze

TOKEN_PATH = "/opt/googleAPI/token.yaml".freeze
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


##INFORMATION
#Metodo usado para corrigir erros comuns no dominio dos e-mails, caso não quiser rodar ele, marque corrigir=false
#
#Method used to correct common errors in the email domain, if you don't want to run it, check correct=false

correct=true
def validaremail(email)##utilizado para validação dos e-mails
if(correct)then
  emailoriginal = email.strip
  emailvalidado=""
  ##contando @ e pontos, ambos tem q ter mais de um para validar um e-mail
  contarroba = email.scan('@').count
  contponto = email.scan('.').count

  ##contando e-mails alterados
  email = email.gsub(' ','') ##tratando espaços vazios
  email = email.gsub("\r",'') ##tratando quebra de linha

  if(!email.nil? && contponto > 0 && contarroba > 0) then

    ##tratando gmail
      email = email.gsub('gmal','gmail')
      email = email.gsub('gmil','gmail')
      email = email.gsub('gmai.com','gmail.com')
      email = email.gsub('gmail.cim','gmail.com')
      email = email.gsub('gmail,com','gmail.com')
      email = email.gsub('gmil.com','gmail.com')
      email = email.gsub('gmial.com','gmail.com')
      email = email.gsub('gmailcom','gmail.com')
      email = email.gsub('gamil.com','gmail.com')

    ##tratando hotmail
      email = email.gsub('hotmal','hotmail')
      email = email.gsub('hotmil','hotmail')
      email = email.gsub('hotmil.com','hotmail.com')
      email = email.gsub('hotmail.com','hotmail.com')
      email = email.gsub('hotmial.com','hotmail.com')
      email = email.gsub('hotmai.com','hotmail.com')
      email = email.gsub('hotmail.cim','hotmail.com')
      email = email.gsub('hotmailcom','hotmail.com')

    ##tratando dominio ueg
      email = email.gsub('alunoueg.br','aluno.ueg.br')
      email = email.gsub('ueg. br','ueg.br')
    ##tratando virgulas
      email = email.gsub(',','')
  emailvalidado = email.strip
#  puts "-- #{emailvalidado}  - #{emailoriginal}"
#p emailvalidado.strip.downcase != emailoriginal.strip.downcase ? "case 1" : "case 2"
  end##fim if(email.nil? && contponto > 0 && contarroba > 0) then

#Differ.format = :color
#puts Differ.diff_by_word(emailoriginal, emailvalidado).to_s
return emailvalidado
else
return email
end
end##fim def validaremail(email)


begin
  ##criando o objeto membro da classe membro do google
  membro = Google::Apis::AdminDirectoryV1::Member.new
  ##definindo os padrões principais para inserir membro
  membro.role="MEMBER"
  membro.type="USER"
  membro.status="ACTIVE"
  membro.kind="admin#directory#member"
  #contando erros e acertos
  count = 0##acertos
  countErro = 0##erros
  qtdemailcorrigido = 0 ##emails corrigidos
  emailscorrigidos = "" ##guardar emails corrigidos
    File.readlines(file).each { |line|
          email=line.split("\n")[0]
             begin
              ##verificando se existe e-mail
              #email0 = email.strip.downcase
              membro.email=validaremail(email)
              #p service.insert_member(groupKey,membro)
              count +=1
              #puts count
            rescue => error
            	if(error.status_code == 404) then
            		mensagemerro = "E-mail não encontrado!"
            	elsif (error.status_code == 409) then
            		mensagemerro = "E-mail ja inserido"
            	else
            		mensagemerro = error.message
            	end

              #p membro.email
              emailserrados = emailserrados + membro.email + ", " + email + ", erro apresentado: #{mensagemerro}, code: #{error.status_code} \n"
              File.open(fileErro, 'a') { |file| file << emailserrados }
              countErro +=1
            end##fim begin verificando se existe e-mail
	 ##contabilizando corrigidos
	    emailvalidado = membro.email
	    emailoriginal = email
		if emailvalidado.strip.downcase != emailoriginal.strip.downcase then
		  puts "- #{emailvalidado}- #{emailoriginal}"
		    emailscorrigidos = "#{emailscorrigidos}#{emailvalidado}, #{emailoriginal}\n"
		    begin
		      File.open(fileCorrecao, 'a') { |file| file << emailcorrigido }
		      rescue Errno::ENOENT
		         p 'file not found'
		      rescue ArgumentError
		         p 'file contains unparsable numbers'
		      rescue
		    end##fi begin
		  else
		  end##fim if emailvalido emailcorigido
          }##fim file.readlines each
	rescue Errno::ENOENT
	   p 'file not found'
	rescue ArgumentError
	     p 'file contains unparsable numbers'
	else##else begin
  		#puts "else"
end##fim begin criando o objeto membro classe

mensagemFinal = mensagemFinal + "Relatório final chamado: #{ticketNumber}\n"
mensagemFinal = mensagemFinal + "Inseridos: #{count}\n"
mensagemFinal = mensagemFinal + "   \n"
mensagemFinal = mensagemFinal + "Erros: #{countErro}\n"
mensagemFinal = mensagemFinal + "#{emailserrados}\n"
mensagemFinal = mensagemFinal + "Corrigidos\n"
mensagemFinal = mensagemFinal + "#{emailscorrigidos}\n"

puts mensagemFinal

