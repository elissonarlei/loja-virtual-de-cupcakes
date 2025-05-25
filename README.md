*Loja Virtual de Cupcakes em Flutter*

Este é o repositório do meu projeto de uma Loja Virtual de Cupcakes, que desenvolvi utilizando Flutter. Foi uma experiência interessante para aplicar e aprender diversos conceitos de desenvolvimento de aplicativos.

Qual a proposta do aplicativo?

Este aplicativo simula uma loja online onde é possível visualizar uma variedade de cupcakes (18 sabores no catálogo), consultar detalhes de cada produto, adicioná-los a um carrinho de compras e simular o processo de um pedido.

Principais funcionalidades:

 * Catálogo de Produtos: Apresentação dos sabores de cupcakes disponíveis.
 * Detalhes do Produto: Acesso a informações como descrição, preço e tabela nutricional para cada item.
 * Carrinho de Compras: Permite adicionar produtos, visualizar os itens selecionados, o valor total e remover itens ou limpar o carrinho completamente.
 * Simulação de Pedido: Permite selecionar uma forma de pagamento (simulado), preencher um formulário de endereço e "finalizar" o pedido.
 * Histórico de Pedidos: Exibe uma lista dos pedidos já realizados no aplicativo.
 * Persistência de Dados: O carrinho e os pedidos são salvos localmente no dispositivo do usuário utilizando Sembast, um banco de dados local.
 * Login Persistente: Após o primeiro login, o aplicativo "lembra" o usuário, não exigindo novas credenciais a cada acesso, a menos que o usuário opte por "Sair".
 * Tema Escuro: A interface utiliza um tema escuro, visando conforto visual.
 * Interface de Login/Cadastro Otimizada: Nas telas de login e cadastro, os elementos de navegação da loja (menu e carrinho) são ocultos para focar no processo de autenticação.

Tecnologias Utilizadas

 * Flutter: Framework para desenvolvimento de interfaces de usuário para múltiplas plataformas a partir de um único código-base.
 * Dart: Linguagem de programação utilizada com o Flutter.
 * Sembast: Banco de dados NoSQL local para persistência de dados no dispositivo.
 * Shared Preferences: Utilizado para armazenar o estado de login do usuário.
 * Unsplash Source API: Para carregamento de imagens de exemplo para os produtos.

Este projeto foi desenvolvido com foco no aprendizado e na demonstração de funcionalidades de um aplicativo de e-commerce.
