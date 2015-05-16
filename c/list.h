typedef struct {
	int time;
	int Y_lon;
	int Y_lat;
	int V_l;
	int V_r;
	int u_Dist;
	int u_Ang;
}data;
typedef struct m{
	data node;
	struct m *next;
	struct m *prev;
} dllist;
extern  dllist *head, *tail;
void append_node( dllist *lnode);
void insert_node( dllist *lnode,  dllist *after);
void printList();
void deleteList();
int countElements();