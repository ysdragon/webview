/*
 * ring_webview_json.h
 * This file is part of the Ring WebView library.
 * Author: Youssef Saeed (ysdragon) <youssefelkholey@gmail.com>
 */

#ifndef RING_WEBVIEW_JSON_H
#define RING_WEBVIEW_JSON_H

#include "yyjson.h"

#define RING_WEBVIEW_JSON_TRUE "__JSON_TRUE__"
#define RING_WEBVIEW_JSON_FALSE "__JSON_FALSE__"
#define RING_WEBVIEW_JSON_EMPTY_OBJECT "__JSON_EMPTY_OBJECT__"

#define IS_JSON_EMPTY_OBJECT(pList)                                                                                    \
	(ring_list_getsize(pList) == 1 && ring_list_isstring(pList, 1) &&                                                  \
	 strcmp(ring_list_getstring(pList, 1), RING_WEBVIEW_JSON_EMPTY_OBJECT) == 0)

static void yyjson_value_to_ring_item(void *pState, yyjson_val *pVal, List *pList)
{
	size_t idx, max;

	if (yyjson_is_obj(pVal))
	{
		List *pObjectList = ring_list_newlist_gc(pState, pList);
		yyjson_val *pKey, *pItemValue;
		yyjson_obj_foreach(pVal, idx, max, pKey, pItemValue)
		{
			List *pPairList = ring_list_newlist_gc(pState, pObjectList);
			ring_list_addstring_gc(pState, pPairList, yyjson_get_str(pKey));
			yyjson_value_to_ring_item(pState, pItemValue, pPairList);
		}
	}
	else if (yyjson_is_arr(pVal))
	{
		List *pArrayList = ring_list_newlist_gc(pState, pList);
		yyjson_val *pItemValue;
		yyjson_arr_foreach(pVal, idx, max, pItemValue)
		{
			yyjson_value_to_ring_item(pState, pItemValue, pArrayList);
		}
	}
	else if (yyjson_is_str(pVal))
	{
		ring_list_addstring_gc(pState, pList, yyjson_get_str(pVal));
	}
	else if (yyjson_is_num(pVal))
	{
		if (yyjson_is_int(pVal))
		{
			long long nInt = (long long)yyjson_get_sint(pVal);
			if (nInt >= -2147483647LL - 1 && nInt <= 2147483647LL)
				ring_list_addint_gc(pState, pList, (int)nInt);
			else
				ring_list_adddouble_gc(pState, pList, (double)nInt);
		}
		else
		{
			ring_list_adddouble_gc(pState, pList, yyjson_get_num(pVal));
		}
	}
	else if (yyjson_is_bool(pVal))
	{
		ring_list_addstring_gc(pState, pList, yyjson_get_bool(pVal) ? RING_WEBVIEW_JSON_TRUE : RING_WEBVIEW_JSON_FALSE);
	}
	else
	{
		/* null -> empty string */
		ring_list_addstring_gc(pState, pList, RING_CSTR_EMPTY);
	}
}

/* Decode a JSON document into a new Ring list parented to the VM temp memory.
 * A single root array/object is unwrapped into the result
 * so a JS arguments array becomes the argument list itself.
 * Returns NULL on parse error. */
static List *json_decode_to_ring_list(VM *pVM, const char *cJson)
{
	yyjson_doc *pDoc;
	yyjson_val *pRoot;
	List *pTempList, *pResultList;

	pTempList = ring_vm_api_newlist(pVM);
	if (!cJson || !*cJson)
		return pTempList;

	pDoc = yyjson_read(cJson, strlen(cJson), 0);
	if (!pDoc)
		return NULL;
	pRoot = yyjson_doc_get_root(pDoc);
	if (pRoot)
		yyjson_value_to_ring_item(pVM->pRingState, pRoot, pTempList);
	yyjson_doc_free(pDoc);

	if (ring_list_getsize(pTempList) == 1 && ring_list_islist(pTempList, 1))
	{
		pResultList = ring_vm_api_newlist(pVM);
		ring_list_swaptwolists_gc(pVM->pRingState, pResultList, ring_list_getlist(pTempList, 1));
		return pResultList;
	}
	return pTempList;
}

static int is_ring_list_a_json_object(List *pList)
{
	unsigned int x;

	if (IS_JSON_EMPTY_OBJECT(pList))
		return 1;
	if (ring_list_getsize(pList) == 0)
		return 0;
	for (x = 1; x <= ring_list_getsize(pList); x++)
	{
		List *pSubList;
		if (!ring_list_islist(pList, x))
			return 0;
		pSubList = ring_list_getlist(pList, x);
		if (!(ring_list_getsize(pSubList) == 2 && ring_list_isstring(pSubList, 1)))
			return 0;
	}
	return 1;
}

static yyjson_mut_val *ring_item_to_yyjson(yyjson_mut_doc *pDoc, void *pState, Item *pItem, List *pVisited);

static yyjson_mut_val *ring_list_to_yyjson(yyjson_mut_doc *pDoc, void *pState, List *pList, List *pVisited)
{
	yyjson_mut_val *pResult;
	unsigned int x;

	/* Cycle detection */
	if (ring_list_findpointer(pVisited, pList))
		return yyjson_mut_null(pDoc);
	ring_list_addpointer_gc(pState, pVisited, pList);

	if (IS_JSON_EMPTY_OBJECT(pList))
	{
		pResult = yyjson_mut_obj(pDoc);
	}
	else if (is_ring_list_a_json_object(pList))
	{
		pResult = yyjson_mut_obj(pDoc);
		for (x = 1; x <= ring_list_getsize(pList); x++)
		{
			List *pPairList = ring_list_getlist(pList, x);
			yyjson_mut_obj_add_val(pDoc, pResult, ring_list_getstring(pPairList, 1),
								   ring_item_to_yyjson(pDoc, pState, ring_list_getitem(pPairList, 2), pVisited));
		}
	}
	else
	{
		pResult = yyjson_mut_arr(pDoc);
		for (x = 1; x <= ring_list_getsize(pList); x++)
		{
			yyjson_mut_arr_add_val(pResult, ring_item_to_yyjson(pDoc, pState, ring_list_getitem(pList, x), pVisited));
		}
	}

	ring_list_deletelastitem_gc(pState, pVisited);
	return pResult;
}

static yyjson_mut_val *ring_item_to_yyjson(yyjson_mut_doc *pDoc, void *pState, Item *pItem, List *pVisited)
{
	switch (ring_item_gettype(pItem))
	{
	case ITEMTYPE_STRING: {
		String *pString = ring_item_getstring(pItem);
		const char *cStr;
		if (ring_string_size(pString) == 0)
			return yyjson_mut_null(pDoc);
		cStr = ring_string_get(pString);
		if (strcmp(cStr, RING_WEBVIEW_JSON_TRUE) == 0)
			return yyjson_mut_true(pDoc);
		if (strcmp(cStr, RING_WEBVIEW_JSON_FALSE) == 0)
			return yyjson_mut_false(pDoc);
		/* yyjson keeps the pointer without copying; the Ring string stays
		 * alive until yyjson_mut_write() is done. */
		return yyjson_mut_str(pDoc, cStr);
	}
	case ITEMTYPE_NUMBER:
		if (pItem->nNumberFlag == ITEM_NUMBERFLAG_INT)
			return yyjson_mut_sint(pDoc, ring_item_getint(pItem));
		return yyjson_mut_real(pDoc, ring_item_getnumber(pItem));
	case ITEMTYPE_LIST:
		return ring_list_to_yyjson(pDoc, pState, ring_item_getlist(pItem), pVisited);
	default:
		return yyjson_mut_null(pDoc);
	}
}

/* Encode a Ring list to a malloc'd JSON string (caller frees).
 * NULL on allocation failure. */
static char *ring_list_to_json_string(void *pState, List *pList)
{
	yyjson_mut_doc *pDoc;
	yyjson_mut_val *pRoot;
	List *pVisited;
	char *cJson;

	pDoc = yyjson_mut_doc_new(NULL);
	if (!pDoc)
		return NULL;
	pVisited = ring_list_new_gc(pState, 0);
	pRoot = ring_list_to_yyjson(pDoc, pState, pList, pVisited);
	ring_list_delete_gc(pState, pVisited);
	if (!pRoot)
	{
		yyjson_mut_doc_free(pDoc);
		return NULL;
	}
	yyjson_mut_doc_set_root(pDoc, pRoot);
	cJson = yyjson_mut_write(pDoc, 0, NULL);
	yyjson_mut_doc_free(pDoc);
	return cJson;
}

/* Encode a number to a malloc'd JSON string (caller frees).
 * Integral values are emitted as integers (5 -> "5", not "5.0"). */
static char *ring_number_to_json_string(double nNumber)
{
	yyjson_mut_doc *pDoc;
	yyjson_mut_val *pVal;
	char *cJson;

	pDoc = yyjson_mut_doc_new(NULL);
	if (!pDoc)
		return NULL;
	if (nNumber == (double)(long long)nNumber && nNumber >= -9007199254740992.0 && nNumber <= 9007199254740992.0)
		pVal = yyjson_mut_sint(pDoc, (long long)nNumber);
	else
		pVal = yyjson_mut_real(pDoc, nNumber);
	cJson = yyjson_mut_val_write(pVal, 0, NULL);
	yyjson_mut_doc_free(pDoc);
	return cJson;
}

#endif /* RING_WEBVIEW_JSON_H */
