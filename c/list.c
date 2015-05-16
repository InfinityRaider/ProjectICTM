#include "list.h"
void append_node(dllist *lnode) {
	if(head == 0) {
		head = lnode;
		lnode->prev = 0;
	} else {
		tail->next = lnode;
		lnode->prev = tail;
	}

	tail = lnode;
	lnode->next = 0;
}
void printList(){
	dllist *lnode;
	if(head == 0){
		return;
	}
	for(lnode = head; lnode != 0; lnode = lnode->next) {
		printf("%d %d %d %d %d %d %d\r\n",  lnode->node.time, lnode->node.Y_lon, lnode->node.Y_lat, lnode->node.V_l, lnode->node.V_r, lnode->node.u_Dist, lnode->node.u_Ang);
	}
}

void remove_node(dllist *lnode) {
	if(lnode->prev == 0)
		head = lnode->next;
	else
		lnode->prev->next = lnode->next;

	if(lnode->next == 0)
		tail = lnode->prev;
	else
		lnode->next->prev = lnode->prev;
}
void deleteList(){
	while(head != 0)
		remove_node(head);

}
int countElements(){
	dllist *lnode;
	int size = 0;
	if(head == 0){
		return 0;
	}
	for(lnode = head; lnode != 0; lnode = lnode->next) 
		size++;
	return size;
}