extends RefCounted

const NAMES = {
	"I021":"Maçã", "I024":"Laranja", "I029":"Pão", "I030":"Biscoito", "I038":"Sopa enlatada", "I040":"Suco",
	"I053":"Lanterna", "I060":"Garrafa", "I066":"Tábua", "I067":"Ripa", "I068":"Tecido", "I069":"Linha",
	"I070":"Fibra", "I071":"Papelão", "I072":"Papel", "I073":"Pigmento", "I074":"Cola de artesanato",
	"I075":"Ferragens", "I078":"Argila", "I079":"Sementes de horta", "I080":"Terra para vaso",
	"I083":"Mapa de papel", "I084":"Rádio de campo", "I091":"Caixote de madeira", "I092":"Cesto de tecido",
	"I093":"Marcador de trilha", "I094":"Tapete artesanal", "I095":"Prateleira pequena", "I096":"Vaso decorativo",
	"I097":"Organizador de mesa", "I098":"Capa de banco", "I099":"Caixa de mudas", "I100":"Painel de recados"
}
const FOOD = {"I021":15,"I024":15,"I029":21,"I030":13,"I038":32}
const RECIPES = {
	"R01":["I091","I066","I075"], "R02":["I092","I068","I069"], "R03":["I093","I067","I073"],
	"R04":["I094","I070","I068"], "R05":["I095","I066","I075"], "R06":["I096","I078","I073"],
	"R07":["I097","I071","I074"], "R08":["I098","I068","I069"], "R09":["I099","I067","I080"],
	"R10":["I100","I066","I072"]
}
const DETAILS = {
	"I053":"Acenda ou apague a lanterna durante a caminhada.", "I060":"Guarda três porções. Encha no reservatório ou na ponte.",
	"I079":"Plante em uma caixa de mudas instalada no abrigo.", "I083":"Consulte a carta do vale na aba Mapa.",
	"I084":"Sintonize o boletim local. Há um transmissor no mirante.", "I040":"Recupera sede e um pouco de fome.",
	"I091":"Instale no abrigo para acrescentar uma caixa de provisões.", "I092":"Instale junto à varanda.",
	"I093":"Leve ao mirante para sinalizar a travessia.", "I094":"Instale no abrigo para ganhar mais energia ao dormir.",
	"I095":"Instale na parede do abrigo.", "I096":"Instale o vaso na varanda.", "I097":"Instale na mesa do abrigo.",
	"I098":"Instale ao lado da perua para revestir o banco.", "I099":"Instale no abrigo para cultivar sementes.",
	"I100":"Instale no abrigo para expor os registros da expedição."
}
const LOOT = {
	"abrigo":{"I060":1,"I084":1,"I029":2,"I079":2},
	"mercado":{"I038":2,"I030":3,"I040":2,"I068":3,"I069":2,"I071":2,"I074":2,"I072":1},
	"oficina":{"I066":4,"I067":3,"I075":3,"I053":1,"I069":1},
	"ponte":{"I073":3,"I070":2,"I068":1},
	"reservatorio":{"I078":2,"I080":2,"I079":2},
	"mirante":{"I024":2}
}
const ENTRIES = {
	"abrigo":"Uma linha a lápis atravessa a carta da mesa: da ponte ao mirante. Alguém queria deixar essa passagem marcada.",
	"mercado":"Na mercearia, uma lista de entregas termina em «caixa azul, junto à ponte». Sobram mantimentos nas prateleiras.",
	"oficina":"O mecânico guardou ripas retas e ferragens. A bancada ainda serve para fabricar o que faltar na viagem.",
	"ponte":"A régua no pilar mostra a antiga cheia. Uma lata de pigmento sobreviveu na caixa azul.",
	"reservatorio":"No registro do reservatório, a última leitura diz «nível estável». Você copia a medição para o boletim.",
	"mirante":"Do alto, o rio parece unir todas as estradas. O rádio da estação ainda tem uma luz acesa."
}
const LABELS = {"abrigo":"Abrigo da Figueira","mercado":"Mercearia","oficina":"Oficina Estação","ponte":"Ponte da Várzea","mirante":"Mirante","reservatorio":"Reservatório"}
const LANDMARKS = ["abrigo","mercado","oficina","ponte","reservatorio","mirante"]

static func description(id: String) -> String:
	if FOOD.has(id):
		return "Uma porção recupera %d pontos de fome." % FOOD[id]
	return DETAILS.get(id,"Material de fabricação. Consulte as combinações na oficina do caderno.")
