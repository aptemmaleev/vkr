import gspread
from gspread_formatting import *

def get_service_account():
    gc = gspread.service_account(
        filename = 'smarthouse-424816-53872d0450a9.json'
    )
    return gc

def create_spreadsheet(house, year, month):
    gc = gspread.service_account(
        filename = 'smarthouse-424816-53872d0450a9.json'
    )
    sh = gc.create(f"{house} - {year}.{month}")
    sh.share(None, role='writer', perm_type='anyone')
    return sh

def write_table(spreadsheet, house, counter_type, table_data):    
    consumed_text = "единиц"
    if counter_type == "electricity": consumed_text = "кВт - ч"
    if counter_type == "hot_water": consumed_text = "куб.м." 
    if counter_type == "cold_water": consumed_text = "куб.м."

    if counter_type == "electricity": counter_type = "ЭЭ"
    if counter_type == "hot_water": counter_type = "ГВС" 
    if counter_type == "cold_water": counter_type = "ХВС"

    ws = spreadsheet.add_worksheet(title=f"{counter_type}", rows=f"{len(table_data) + 10}", cols="20")

    ws.merge_cells("B1:F1", merge_type='MERGE_ALL')
    ws.merge_cells("A3:F3", merge_type='MERGE_ALL')

    table_data.insert(0, ["Дом:", house])
    table_data.insert(1, [])
    table_data.insert(2, [f"Журнал учета показаний {counter_type}"])
    table_data.insert(3, [f"№\nп/п", "Адрес", "Серийный номер счетчика", f"Пред. показания\n{consumed_text}", f"Тек. показания\n{consumed_text}", f"Количество потреблен.\n{consumed_text}"])

    ws.format('A3:F3', {"textFormat": {"bold": True, "fontSize": 14}, "horizontalAlignment": "CENTER"})
    # ws.format('A:A', {'width': 40})
    ws.update(table_data)