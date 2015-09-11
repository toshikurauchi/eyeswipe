
var Languages = {
    EN: 0,
    PT: 1
}

var language = Languages.EN;

var en2pt = {
    "Thank you!": "Obrigado!",
    "Session ": "Sessao ",
    "\nPress <Space> to start": "\nPressione <Espaco> para comecar",
    "Paused": "Parado",
    "Select": "Selecionar",
    "Add space": "Adicionar espaco",
    "Cancel": "Cancelar",
    "Delete word": "Remover palavra",
    "Delete character": "Remover caractere",
    "Continuous": "Continuo",
    "Single": "Caractere",
    "Start": "Comecar",
    "No word found": "Palavra nao encontrada",
    "End": "Fim"
}

function setLanguage(newLanguage) {
    language = newLanguage;
}

function tr(str) {
    if (language === Languages.PT && str in en2pt) return en2pt[str];
    return str;
}
