%{
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <termios.h>
#include <unistd.h>


int Start(int h, int w, int ch, int sth, int stw, int var);
void FreeMaze(char** maze, int height);

int yylex();
void yyerror(const char *s);


int height = 0;
int width = 0;

int starth = 1;
int startw = 1;

int choice = 0;


%}

%union {
	int intval;
}

%token <intval> NUMBER
%token GENERATE NEWLINE SOLVE SIZE CHOICE POSITION WALK EXIT HELP

%type <intval> choice;

%% 

program: %empty
	| program SIZE NUMBER NUMBER NEWLINE {
		height = $3;
		width = $4;
		printf("Размеры лабиринта установлены: %d x %d\n", height, width);
	}
	| program CHOICE NUMBER NEWLINE{
		choice = $3;
		switch(choice) {
			case 1:		printf("Выбран 1 вариант лабиринта\n");		break;
			case 2:		printf("Выбран 2 вариант лабиринта\n");		break;
			default:	printf("ERROR: Такого типа лабиринта нет\n");	break;
		}
	}
	| program POSITION NUMBER NUMBER NEWLINE {
		starth = $3;
		startw = $4;
		printf("Позиция игрока обозначена: %d, %d\n", starth, startw);
	}
	| program HELP NEWLINE {
		printf("Есть два типа генерации лабиринта:\n\nПервый в котором - Точка начала и конца уже определены\nГенерация происходит с помощью случайного выбора движения\n\nВторой - Пользователь вводит начальную точку(position)\nГенерация происходит с помощью случайного выбора движения, но реализация сложнее, использовался стек\n\n\nНастройки:\nsize - настраивает высоту и длину лабиринта\nНапример: \"size 43 38\"\n!!! Желательно устанавливать размеры лабиринта не менее 10x10 !!!\n\nposition - настраивает начальную позицию игрока в лабиринте\nНапример: \"position 14 12\"\n!!! Начальная позиция должна быть меньше размеров лабиринта и больше 1 !!!\n\nchoice - настраивает тип лабиринта Например: \"choice 2\"\n!!! Возможны ДВЕ настройки, описанные выше !!!\n\ngenerate - После настроек лабиринта можно его создавать\nЕСЛИ ХОТИТЕ ПРОЙТИ ЛАБИРИНТ ВВЕДИТЕ \"generate walk\"\nЕСЛИ ХОТИТЕ УВИДЕТЬ ПРОХОЖДЕНИЕ ВВЕДИТЕ \"generate exit\"\n\n\n");
	}
	| program GENERATE choice NEWLINE {
		if (width == 0 || height == 0 || (choice != 1 && choice != 2) || startw >= width || starth >= height || startw == 0 || starth == 0) {
			printf("Нехватает параметров или они невозможные!\n");
    		} else {
    			Start(height, width, choice, starth, startw, $3);
    		}
	}
	;
choice: %empty { $$ = 0; }
	| WALK{
		$$ = 1;
	}
	| EXIT{
		$$ = 2;
	}
	;

%%
typedef struct {
    int x, y;
} Point;

Point* stack;
int stack_top = -1;

void push(Point p) {
    stack[++stack_top] = p;
}

Point pop() {
    return stack[stack_top--];
}

char** createMaze(int height, int width) {
	char** maze = malloc(height * sizeof(char*));
	if (maze == NULL) {
		printf("Не хватает памяти");
		exit(EXIT_FAILURE);
	}
	
	for (int i = 0; i < height; i++) {
		maze[i] = malloc(width * sizeof(char));
		if (maze[i] == NULL) {
	    		printf("Не хватает памяти");
	    		exit(EXIT_FAILURE);
		}
	}

	return maze;
}

void DisplayMaze(char** maze, int h, int w, int door) {

	for(int i = 0; i < h; i++) {
		for(int j = 0; j < w; j++) {
			if (door == 6 && maze[i][j] == 5){
				maze[i][j] = 6;
			}
			switch(maze[i][j]) {
				case 1:		printf("[]");	break;	// Стена
				case 2:		printf("<>");	break;	// Решение
				case 3:		printf("$$");	break;	// Позиция игрока
				case 4:		printf("|-");	break;  // Ключ
				case 5:		printf("><");	break;  // Дверь закрытая
				case 6:		printf("::");	break;  // Дверь открытая
				default:	printf("  ");	break;	// Коридор
			}
		}
		printf("\n");
	}
	printf("\n");
}


void PierceMaze1(char** maze, int h, int w) {
	maze[1][1] = 0;
	int* key;
	int x1, y1, xsh;
	int x2, y2, ysh;
	int dx, dy;
	int dir, count, score, random;
	score = 0;
	key = (int*)malloc(w * h * 2 * sizeof(int));
	
	if(key == NULL) {
		printf("Не хватает памяти");
		exit(EXIT_FAILURE);
	}
	for (int y = 1; y < h - 1; y += 2) {
		for (int x = 1; x < w - 1; x += 2) {
			xsh = x;
			ysh = y;
			dir = rand() % 4;
			count = 0;
				
			while(count < 4) {
				dx = 0; dy = 0;
				switch(dir) {
					case 0:		dy = 1;		break;	// Вниз
					case 1:		dx = -1;	break;	// Влево
					case 2:		dx = 1;		break;	// Вправо
					default:	dy = -1;	break;	// Вверх
				}
				x1 = xsh + dx;
				y1 = ysh + dy;
				x2 = x1 + dx;
				y2 = y1 + dy;

				if (x2 >= 0 && x2 < w && y2 >= 0 && y2 < h && maze[y1][x1] == 1 && maze[y2][x2] == 1) {
					maze[y1][x1] = 0;
					maze[y2][x2] = 0;
					xsh = x2;
					ysh = y2;
					dir = rand() % 4;
					count = 0;
				} else {
					dir = (dir + 1) % 4;
					count += 1;
					if (count == 4) {
						key[2 * score] = xsh;
						key[2 * score + 1] = ysh;
						score = score + 1;
					}
				}
			}
		}
	}
	if (score > 0){
		maze[key[score - 2]][key[score - 1]] = 5;
		random = rand() % score;
		maze[key[random * 2 + 1]][key[random * 2]] = 4;
	}
	maze[1][1] = 3;
	free(key);
}

void findexit(char** maze, int h, int w, int sth, int stw) {
	stack = malloc(w * h * sizeof(Point));
	int oldx = 0;
	int oldy = 0;
	int door = 5;
	int check = 0;
	if (stack == NULL) {
		perror("Не удалось выделить память под stack");
		exit(EXIT_FAILURE);
	}
	push((Point){stw, sth});

	int directions[4][2] = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};
	while (stack_top != -1 && check == 0) {
		Point current = pop();
		maze[current.y][current.x] = 3;
		int neighbors[4][2];
		int count = 0;

		// Находим все возможные направления
		for (int i = 0; i < 4; i++) {
			int nx = current.x + directions[i][0];
			int ny = current.y + directions[i][1];
			if (maze[ny][nx] == 5){
				check = 1;
			}
			if (maze[ny][nx] != 1 && (ny != oldy || nx != oldx) && maze[ny][nx] != 2) {
				if (stack_top != -1){
					Point next = pop();
					if (next.y != ny || next.x != nx){
						neighbors[count][0] = directions[i][0];
						neighbors[count][1] = directions[i][1];
						count++;
					}
					push(next);
				}
				else{
					neighbors[count][0] = directions[i][0];
					neighbors[count][1] = directions[i][1];
					count++;
				}
			}
		}
		
		if (count == 0){
			oldx = current.x;
			oldy = current.y;
			maze[oldy][oldx] = 2;
			
			Point next = pop();
			maze[next.y][next.x] = 3;
			push(next);
		}
		
		if (count > 0) {
			// Возвращаем текущую клетку в стек
			push(current);

			// Выбираем случайное направление
			int rand_index = rand() % count;
			int dx = neighbors[rand_index][0];
			int dy = neighbors[rand_index][1];

			
			// Переходим в соседнюю клетку
			maze[current.y][current.x] = 2;
			maze[current.y + dy][current.x + dx] = 3;
			push((Point){current.x + dx, current.y + dy});
			oldx = current.x;
			oldy = current.y;
		}
		usleep(50000);
		system("clear");
		DisplayMaze(maze, h, w, door);
	}
	free(stack);
	FreeMaze(maze, h);
}

void PierceMaze2(char** maze, int h, int w, int sth, int stw) {
	int score = 0;
	int* key;
	key = (int*)malloc(w * h * 2 * sizeof(int));
	stack = malloc(w * h * sizeof(Point));
	if (stack == NULL) {
		perror("Не удалось выделить память под stack");
		exit(EXIT_FAILURE);
	}
	maze[sth][stw] = 3; // Начальная точка
	push((Point){stw, sth});

	int directions[4][2] = {{2, 0}, {0, 2}, {-2, 0}, {0, -2}};
	while (stack_top != -1) {
		Point current = pop();
		int neighbors[4][2];
		int count = 0;

		// Находим все возможные направления
		for (int i = 0; i < 4; i++) {
			int nx = current.x + directions[i][0];
			int ny = current.y + directions[i][1];
			if (nx >= 0 && nx <= w - 1 && ny > 0 && ny < h - 1 && maze[ny][nx] == 1) {
				neighbors[count][0] = directions[i][0];
				neighbors[count][1] = directions[i][1];
				count++;
			}
		}
		
		if (count == 0) {
			if(key == NULL) {
				printf("Не хватает памяти");
				exit(EXIT_FAILURE);
			}
			key[2 * score] = current.x;
			key[2 * score + 1] = current.y;
			score = score + 1;
		}

		if (count > 0) {
			// Возвращаем текущую клетку в стек
			push(current);

			// Выбираем случайное направление
			int rand_index = rand() % count;
			int dx = neighbors[rand_index][0];
			int dy = neighbors[rand_index][1];

			// Удаляем стену между текущей и соседней клеткой
			maze[current.y + dy / 2][current.x + dx / 2] = ' ';
			// Переходим в соседнюю клетку
			maze[current.y + dy][current.x + dx] = ' ';
			push((Point){current.x + dx, current.y + dy});
		}
	}
	if (score > 0){
		int random = rand() % score;
		maze[key[random * 2 + 1]][key[random * 2]] = 5;
		random = rand() % score;
		maze[key[random * 2 + 1]][key[random * 2]] = 4;
	}
	free(stack);
	free(key);
}

void GenerationMaze(char** maze, int h, int w, int ch, int sth, int stw) {
	
	/* Лабиринт из стен */
	for(int i = 0; i < h; i++) {
		for(int j = 0; j < w; j++) {
			maze[i][j] = 1;
		}
	}
	
	switch(ch) {
		case 1:	PierceMaze1(maze, h, w);		break;
		case 2:	PierceMaze2(maze, h, w, sth, stw);	break;
		maze[sth][stw] = 3;
	}
}

char get(void) {
	char buf = 0;
	struct termios old = {0};
	if (tcgetattr(0, &old) < 0)
		perror ("tcsetattr()");
	old.c_lflag &= ~ICANON;		// Выключаем канонический ввод
	old.c_lflag &= ~ECHO;		// Выключаем отображение ввода
	old.c_cc[VMIN] = 1;		// Минимальное количество вводимых символов
	old.c_cc[VTIME] = 0;		// Таймаут
	if (tcsetattr(0, TCSANOW, &old) < 0)
		perror ("tcsetattr()");
	if (read(0, &buf, 1) < 0)
		perror ("read()");
	old.c_lflag |= ICANON;		// Включаем обратно канонический ввод
	old.c_lflag |= ECHO;		// Включаем отображение ввода
	tcsetattr(0, TCSANOW, &old);
	return (buf);
}

void Movement(char** maze, int h, int w, int sth, int stw){
	int k = 0;
	int door = 5;
	char command;
	int ply = sth;
	int plx = stw;
	while (k == 0) {
		system("clear");			// Очистка экрана (для Unix/Linux)
		DisplayMaze(maze, h, w, door);
		
		printf("Введите команду (w/a/s/d для движения, q для выхода)\nВЫ - \"$$\"\nКЛЮЧ - \"|-\"\nДВЕРЬ ЗАКРЫТАЯ - \"><\"\nДВЕРЬ ОТКРЫТАЯ - \"::\"\n");
		command = get();			// Читаем один символ

		// Обработка команд
		if (command == 'w' && ply > 0 && maze[ply][plx] != 1 && maze[ply - 1][plx] != 1) {
			if (maze[ply - 1][plx] == 5 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Дверь
				maze[ply - 1][plx] = 5;
				ply = ply - 1;
			} else if (maze[ply][plx] == 5){
				maze[ply][plx] = 5;	// Дверь
				maze[ply - 1][plx] = 3;
				ply = ply - 1;
			} else if (maze[ply - 1][plx] == 4 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Ключ
				maze[ply - 1][plx] = 3;
				ply = ply - 1;
				door = 6;
			} else if (maze[ply - 1][plx] == 6){
				maze[ply][plx] = 0;
				ply = ply - 1;
				system("clear");
				printf("Поздравляю!!! Лабиринт пройден. Можете снова вводить команды\n");
				k = 1;
			} else if (maze[ply][plx] != 5){
				maze[ply][plx] = 0;	// Движение вверх
				maze[ply - 1][plx] = 3;
				ply = ply - 1;
			}
		} else if (command == 's' && ply < h - 1 && maze[ply][plx] != 1 && maze[ply + 1][plx] != 1) {
			if (maze[ply + 1][plx] == 5 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Дверь
				maze[ply + 1][plx] = 5;
				ply = ply + 1;
			} else if (maze[ply][plx] == 5){
				maze[ply][plx] = 5;	// Дверь
				maze[ply + 1][plx] = 3;
				ply = ply + 1;
			} else if (maze[ply + 1][plx] == 4 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Ключ
				maze[ply + 1][plx] = 3;
				ply = ply + 1;
				door = 6;
			} else if (maze[ply + 1][plx] == 6){
				maze[ply][plx] = 0;
				system("clear");
				printf("Поздравляю!!! Лабиринт пройден. Можете снова вводить команды\n");
				k = 1;
				ply = ply + 1;
			} else if (maze[ply][plx] != 5){
				maze[ply][plx] = 0;	// Движение вниз
				maze[ply + 1][plx] = 3;
				ply = ply + 1;
			}
		} else if (command == 'a' && plx > 0 && maze[ply][plx] != 1 && maze[ply][plx - 1] != 1) {
			if (maze[ply][plx - 1] == 5 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Дверь
				maze[ply][plx - 1] = 5;
				plx = plx - 1;
			} else if (maze[ply][plx] == 5){
				maze[ply][plx] = 5;	// Дверь
				maze[ply][plx - 1] = 3;
				plx = plx - 1;
			} else if (maze[ply][plx - 1] == 4 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Ключ
				maze[ply][plx - 1] = 3;
				plx = plx - 1;
				door = 6;
			} else if (maze[ply][plx - 1] == 6){
				maze[ply][plx] = 0;
				plx = plx - 1;
				system("clear");
				printf("Поздравляю!!! Лабиринт пройден. Можете снова вводить команды\n");
				k = 1;
			} else if (maze[ply][plx] != 5){
				maze[ply][plx] = 0;	// Движение влево
				maze[ply][plx - 1] = 3;
				plx = plx - 1;
			}
		} else if (command == 'd' && plx < w - 1 && maze[ply][plx] != 1 && maze[ply][plx + 1] != 1) {
			if (maze[ply][plx + 1] == 5 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Дверь
				maze[ply][plx + 1] = 5;
				plx = plx + 1;
			} else if (maze[ply][plx] == 5){
				maze[ply][plx] = 5;	// Дверь
				maze[ply][plx + 1] = 3;
				plx = plx + 1;
			} else if (maze[ply][plx + 1] == 4 && maze[ply][plx] == 3){
				maze[ply][plx] = 0;	// Ключ
				maze[ply][plx + 1] = 3;
				plx = plx + 1;
				door = 6;
			} else if (maze[ply][plx + 1] == 6){
				maze[ply][plx] = 0;
				plx = plx + 1;
				system("clear");
				printf("Поздравляю!!! Лабиринт пройден. Можете снова вводить команды\n");
				k = 1;
			} else if (maze[ply][plx] != 5){
				maze[ply][plx] = 0;	// Движение вправо
				maze[ply][plx + 1] = 3;
				plx = plx + 1;
			}
		} else if (command == 'q') {
			system("clear");
			printf("Можете снова вводить команды\n");
			break;	// Выход из игры
		} else {
			printf("Неверная команда или движение невозможно!\n");
		}
	}
	FreeMaze(maze, h);
}

void FreeMaze(char** maze, int height) {
	for (int i = 0; i < height; i++) {
		free(maze[i]);
	}
	free(maze);
}

int Start(int h, int w, int ch, int sth, int stw, int var) {
	int door = 5;
	printf("\033[H\033[J"); // ANSI-коды для очистки терминала
	srand(time(0));
	if(w % 2 == 0){
		w = w + 1;
	}
	if(h % 2 == 0){
		h = h + 1;
	}
	if(sth % 2 == 0){
		sth = sth + 1;
	}
	if(stw % 2 == 0){
		stw = stw + 1;
	}
	
	
	char** maze = createMaze(h, w);
	GenerationMaze(maze, h, w, ch, sth, stw);
	DisplayMaze(maze, h, w, door);
	
	if (ch == 1){
		sth = 1;
		stw = 1;
	}
	switch(var) {
		case 1:	Movement(maze, h, w, sth, stw);	break;
		
		case 2: findexit(maze, h, w, sth, stw);	break;
		
		default: FreeMaze(maze, h);		break;
	}
	return 0;
}

int main(void) {
	printf("Справка по командам - \"help\"\n Пример генерации лабиринта:\nsize 31 35\nchoice 2\nposition 2 4\ngenerate walk\nСоздаст лабиринт размером 31x35, второго типа, с стартовой точкой 2:4, который можно обудет пройти\n\n\n");
	return yyparse();
}

void yyerror(const char *s) {
	fprintf(stderr, "ERROR: %s\n", s);
}
