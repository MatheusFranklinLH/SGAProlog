/* dados inicio */

/*Armazenando dados com a biblioteca persistency*/

:- module(user_db,
          [ attach_user_db/1,           % +File
            current_estudante/1,
            current_curso/1,
            current_disciplina/1,
            current_cursa/2,
            current_disc_obrig/2,
            current_nota_final/3,
            add_estudante/1,
            add_curso/1,
            add_disciplina/1,     
            add_cursa/2,
            add_disc_obrig/2,
            add_nota_final/3,
            set_estudante/1,
            set_curso/1,
            set_disciplina/1,           
            set_cursa/2,
            set_disc_obrig/2,
            set_nota_final/3          
          ]).
:- use_module(library(persistency)).

:- persistent
        estudante(aluno:atom),
        curso(curso:atom),
        disciplina(disc:atom),
        cursa(aluno:atom, curso:atom),
        disc_obrig(curso:atom, disc:atom),
        nota_final(aluno:atom, disc:atom, nota:float).

attach_user_db(File) :-
        db_attach(File, []).

current_estudante(Nome) :-
    with_mutex(user_db, estudante(Nome)).
current_curso(Nome) :-
    with_mutex(user_db, curso(Nome)).
current_disciplina(Nome) :-
    with_mutex(user_db, disciplina(Nome)).
current_cursa(Nome, Curso) :-
    with_mutex(user_db, cursa(Nome, Curso)).
current_disc_obrig(Curso, Disc) :-
    with_mutex(user_db, disc_obrig(Curso, Disc)).
current_nota_final(Aluno, Disc, Nota) :-
    with_mutex(user_db, nota_final(Aluno, Disc, Nota)).

add_estudante(Nome) :-
    assert_estudante(Nome).
add_curso(Nome) :-
    assert_curso(Nome).
add_disciplina(Disc) :-
    assert_disciplina(Disc).
add_cursa(Nome, Curso) :-
    assert_cursa(Nome, Curso).
add_disc_obrig(Curso, Disc) :-
    assert_disc_obrig(Curso, Disc).
add_nota_final(Aluno, Disc, Nota) :-
    assert_nota_final(Aluno, Disc, Nota).

set_estudante(Nome) :-
    estudante(Nome), !.
set_estudante(Nome) :-
    with_mutex(user_db, (retractall_estudante(Nome), assert_estudante(Nome))).
set_curso(Nome) :-
    curso(Nome), !.
set_curso(Nome) :-
    with_mutex(user_db, (retractall_curso(Nome), assert_curso(Nome))).
set_disciplina(Nome) :-
    disciplina(Nome), !.
set_disciplina(Nome) :-
    with_mutex(user_db, (retractall_disciplina(Nome), assert_disciplina(Nome))).
set_cursa(Nome, Curso) :-
    cursa(Nome, Curso), !.
set_cursa(Nome, Curso) :-
    with_mutex(user_db, (retractall_cursa(Nome, _), assert_cursa(Nome, Curso))).
set_disc_obrig(Curso, Disc) :-
    disc_obrig(Curso, Disc), !.
set_disc_obrig(Curso, Disc) :-
    with_mutex(user_db, (retractall_disc_obrig(Curso, _), assert_disc_obrig(Curso, Disc))).
set_nota_final(Aluno, Disc, Nota) :-
    nota_final(Aluno, Disc, Nota), !.
set_nota_final(Aluno, Disc, Nota) :-
    with_mutex(user_db, (retractall_nota_final(Aluno, Disc, _), assert_nota_final(Aluno, Disc, Nota))).

:- attach_user_db(database).


/*dados fim*/

/*Funções*/

/*Histórico Escolar*/
/*Retorna uma lista Z com todas as disciplinas e notas em cada disciplina para o aluno X
    historico(Aluno, List) */
junta_lista_tupla([], [], []).
junta_lista_tupla([H1|[]], [H2|[]], [(H1, H2)]).
junta_lista_tupla([H1|T1], [H2|T2], [(H1, H2) | L]):- junta_lista_tupla(T1, T2, L).
historico(X, Z) :- findall(Y, nota_final(X, _, Y), Z1), findall(T, nota_final(X, T, _), Z2), junta_lista_tupla(Z2, Z1, Z).

/*Matriz Curricular*/
/*Encontra matriz curricular do curso X e armazena numa lista Z:
    matriz_curricular (Curso, List) */

matriz_curricular(X, Z) :- findall(Y, disc_obrig(X, Y), Z). 



/*Estudantes que ja cursaram uma disciplina*/
/*Retorna uma lista Z contendo todos os estudantes que cursaram a disciplina X
    cursaram(Disciplina, List)*/
cursaram(X, Z) :- findall(Y, nota_final(Y, X, _), Z).

/*Retorna uma lista L contendo todos os estudantes que cursaram a disciplina D com nota final maior ou igual a N
    cursaram(Disciplina, List)*/
cursou(Aluno, Disciplina, Nota) :- estudante(Aluno), disciplina(Disciplina), nota_final(Aluno, Disciplina, Nota).
add(E, L, [E|L]).
aux_disc([], [], _, _).
aux_disc([H|T], Z, D, N) :- cursou(H, D, N1), N1 >= N -> aux_disc(T, L, D, N), add((H, N1), L, Z); aux_disc(T, Z, D, N).
cursaram_nota(D, L, N) :- cursaram(D, Z), aux_disc(Z, L1, D, N), sort(2, @>, L1, L).





/*Disciplinas que faltam para um estudante*/
/*Retorna uma lista R com todas as disciplinas que faltam para o aluno X formar*/
disciplinas_faltam(X, R) :- cursa(X, Y), matriz_curricular(Y, L1), findall(W, nota_final(X, W, _), L2), subtract(L1, L2, R).




/*Estudantens de um dado curso com critério de maior Ira*/
/*Recebe uma lista Z, com todas as notas do aluno X:
    lista_notas(Aluno, List)*/
lista_notas(X, Z) :-findall(Y, nota_final(X, _, Y), Z).

/*Retorna um N que é a soma de todos os valores na Lista Z:
    soma_lista(List, Int)*/
soma_lista([], 0).
soma_lista([H|T], N) :- soma_lista(T, N1), N is N1+H.

/*Calcula o Ira (N), do aluno X com funcoes aux*/

ira(X, N) :- lista_notas(X, Z), soma_lista(Z, N1), length(Z, N2), N2 > 0 -> N is N1/N2; N is 0.

/*Retorna uma lista Z, com todos os estudantes do curso X e seus respectivos ira
    lista_estudantes_ira(Curso, List)*/

aux([],[], _).
aux([H|T], Z, N) :- ira(H, N1), N1 >= N -> aux(T, L, N), add((H,N1), L, Z); aux(T, Z, N).
lista_estudantes(X, Z) :- findall(Y, cursa(Y, X), Z).
lista_estudantes_ira(X, Z, N) :- lista_estudantes(X, Y), aux(Y, Z, N).

/*Encontra uma lista Z com todos os estudantes de um determinado curso X com ira maior ou igual a N:
    estudantes_ira(Curso, List, Number)*/
estudantes_ira(X, Z, N) :- lista_estudantes_ira(X, L, N), sort(2, @>, L, Z).

/*Encontra uma lista Z com todos os estudantes de um determinado curso X com nota final maior ou igual a N na disciplina D:
    estudantes_disc(Curso, Disciplina, List, Number)*/

estudantes_disc(C, D, L, N) :- lista_estudantes(C, Y), aux_disc(Y, Z, D,  N), sort(2, @>, Z, L).

/*Cursos que contem uma determinada disciplina*/
/*Encontra uma lista Z com todos os cursos que contem a disciplina X:
    cursos_contem(Disciplina, List)*/

cursos_contem(X, Z) :- findall(Y, disc_obrig(Y, X), Z).


/*Menu database*/

menuD(1):-
    write('Digite o nome do estudante:' ), nl,
    read(X),
    add_estudante(X), nl.

menuD(2):-
    write('Digite o nome do curso:' ), nl,
    read(X),
    add_curso(X), nl.

menuD(3):-
    write('Digite o nome da disciplina:' ), nl,
    read(X),
    add_disciplina(X), nl.

menuD(4) :-
    write('Digite o nome do estudante que deseja remover: '), nl,
    read(X),
    with_mutex(user_db, (retract_estudante(X), retractall_cursa(X, _), retractall_nota_final(X, _, _))).

menuD(5) :-
    write('Digite o nome do curso que deseja remover: '), nl,
    read(X),
    with_mutex(user_db, (retract_curso(X), retractall_cursa(_, X), retractall_disc_obrig(X, _))).

menuD(6) :-
    write('Digite o nome da disciplina que deseja remover: '), nl,
    read(X),
    with_mutex(user_db, (retract_disciplina(X), retractall_disc_obrig(_, X), retractall_nota_final(_, X, _))).

menuD(7) :-
    write('Digite o nome do estudante que deseja adicionar: '), nl,
    read(X),
    write('Digite o curso do estudante: '), nl,
    read(Z),
    current_estudante(X),
    current_curso(Z),
    add_cursa(X, Z), nl.

menuD(8) :-
    write('Digite o nome do estudante que deseja alterar: '), nl,
    read(X),
    write('Digite o novo curso do estudante: '), nl,
    read(Z),
    current_estudante(X),
    current_curso(Z),
    set_cursa(X, Z), nl.

menuD(9) :-
    write('Digite o nome da disciplina que deseja adicionar: '), nl,
    read(X),
    write('Digite o nome do curso a qual ela pertence: '), nl,
    read(Z),
    current_disciplina(X),
    current_curso(Z),
    add_disc_obrig(Z, X), nl.

menuD(10) :- 
    write('Digite o nome da disciplina que deseja remover: '), nl,
    read(X),
    write('Digite o nome do curso o qual vai ser feita a remocao: '), nl,
    read(Z),
    current_disciplina(X),
    current_curso(Z),
    with_mutex(user_db, (retract_disc_obrig(Z, X))).

menuD(11) :-
    write('Digite o nome da disciplina que deseja alterar: '), nl,
    read(X),
    write('Digite o nome do novo curso da disciplina: '), nl,
    read(Z),
    current_disciplina(X),
    current_curso(Z),
    set_disc_obrig(Z, X), nl.

menuD(12) :-
    write('Digite o nome do aluno: '), nl,
    read(X),
    write('Digite o nome da disciplina: '), nl,
    read(D),
    write('Digite a nota final: '), nl,
    read(N),
    current_disciplina(D),
    current_estudante(X),
    add_nota_final(X, D, N), nl.

menuD(13) :-
    write('Digite o nome do aluno: '), nl,
    read(X),
    write('Digite o nome da disciplina: '), nl,
    read(D),
    current_disciplina(D),
    current_estudante(X),
    current_nota_final(X, D, _),
    with_mutex(user_db, (retractall_nota_final(X, D, _))).

menuD(14) :-
    write('Digite o nome do aluno: '), nl,
    read(X),
    write('Digite o nome da disciplina: '), nl,
    read(D),
    write('Digite a nova nota final: '), nl,
    read(N),
    current_disciplina(D),
    current_estudante(X),
    set_nota_final(X, D, N), nl.

menuD(15) :-
    menu.

/* Menu principal*/
relacao_estudantes(0, X) :-
    lista_estudantes(X, Z),
    write(Z), nl.

relacao_estudantes(1, X) :-
    write('Qual disciplina deverá ser usada como critério: '), nl,
    read(D),
    current_disciplina(D),
    write('Mostrar alunos com nota maior ou igual a: '), nl,
    read(N),
    estudantes_disc(X, D, Z, N),
    write(Z).

relacao_estudantes(2, X) :-
    write('Exibir alunos com ira maior ou igual a: '), nl,
    read(N),
    estudantes_ira(X, Z, N),
    write(Z).


action_for(1) :-
    write('Digite o nome do estudante: (Necessário aspas caso seja um nome composto)'), nl,
    read(X),
    current_estudante(X),
    historico(X, Z),
    write(Z), nl.

action_for(2) :-
    write('Digite o curso desejado: (Necessário aspas caso seja um nome composto)'), nl,
    read(X),
    current_curso(X),
    matriz_curricular(X, Z),
    write(Z), nl. 

action_for(3) :-
    write('Digite a disciplina desejada: (Necessário aspas caso seja um nome composto)'), nl,
    read(X),
    write('Deseja mostrar alunos com notas maior ou igual a: (Caso deseje mostrar todos responda com 0)'), nl,
    read(N),
    current_disciplina(X),
    cursaram_nota(X, Z, N),
    write(Z), nl.

action_for(4) :-
    write('Digite o nome do estudante desejado: (Necessário aspas caso seja um nome composto)'), nl,
    read(X),
    current_estudante(X),
    disciplinas_faltam(X, Z),
    write(Z), nl.

action_for(5) :-
    write('Digite o curso desejado: (Necessário aspas caso seja um nome composto)'), nl,
    read(X),
    write('Deseja incluir critérios por nota em disciplina ou IRA? (0 - Não, 1 - Nota em disciplina, 2 - IRA'), nl,
    read(A),
    current_curso(X),
    relacao_estudantes(A, X).

action_for(6) :-
    write('Digite a disciplina desejada: (Necessário aspas caso seja um nome composto)'), nl,
    read(X),
    current_disciplina(X),
    cursos_contem(X, Z),
    write(Z), nl.

action_for(7) :-
    repeat, nl, nl,
    write('-------Database-------'), nl,
    write('1. Adicionar estudante'), nl,
    write('2. Adicionar curso'), nl,
    write('3. Adicionar disciplina'), nl,
    write('4. Remover estudante'), nl,
    write('5. Remover um curso'), nl,
    write('6. Remover uma disciplina'), nl,
    write('7. Adicionar estudante a um curso'), nl,
    write('8. Editar curso de um estudante'), nl,
    write('9. Adicionar disciplina a um curso'), nl,
    write('10. Remover disciplina de um curso'), nl,
    write('11. Alterar curso de uma disciplina'), nl,
    write('12. Adicionar nota final de um aluno para uma disciplina'), nl,
    write('13. Remover nota final de um aluno para uma disciplina'), nl,
    write('14. Alterar nota final de um aluno para uma disciplina'), nl,
    write('15. Voltar'), nl,
    write('Choose : '),
    read(Z),
    ( Z = 16 -> !, fail ; true ), 
    menuD(Z),
    fail.



action_for(8) :-
    halt.

menu :-
    repeat, nl, nl,
    write('-------MENU-------'), nl,
    write('1. Consultar Historico Escolar de um estudante'), nl,
    write('2. Consultar Matriz Curricular de um curso'), nl,
    write('3. Consultar Estudantes que já cursaram uma disciplina'), nl,
    write('4. Consultar Disciplinas que faltam para um estudante'), nl,
    write('5. Consultar relacao de estudantes de um curso'), nl,
    write('6. Consultar cursos que contem uma disciplina'), nl,
    write('7. Adicionar/Remover/Editar base de dados'), nl,
    write('8. Exit'), nl,
    write('Choose : '),
    read(Z),
    ( Z = 9 -> !, fail ; true ), 
    action_for(Z),
    fail.

:- menu.


    