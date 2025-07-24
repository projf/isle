# Isle.Computer - Display Controller Test Data
# Copyright Isle Authors
# SPDX-License-Identifier: MIT

"""Display timing data for display tests."""

DT = [
    {  # mode 0 = 640x480
        'PIX_TIME' :    39.68,  # 25.2 MHz
        'HRES'       : 640,
        'VRES'       : 480,
        'H_POL'      :   0,  # negative polarity
        'H_BLANK'    : 160,
        'H_FRONT'    :  16,
        'H_SYNC'     :  96,
        'V_POL'      :   0,  # negative polarity
        'V_BLANK'    :  45,
        'V_FRONT'    :  10,
        'V_SYNC'     :   2
    },
    {  # mode 2 = 1024x768
        'PIX_TIME' :    13.38, # 65 MHz
        'HRES'       :1024,
        'VRES'       : 768,
        'H_POL'      :   0,  # negative polarity
        'H_BLANK'    : 320,
        'H_FRONT'    :  24,
        'H_SYNC'     : 136,
        'V_POL'      :   0, # negative polarity
        'V_BLANK'    :  38,
        'V_FRONT'    :   3,
        'V_SYNC'     :   6
    },
    {  # mode 2 = 1366x768
        'PIX_TIME' :    13.89,  # 72 MHz
        'HRES'       :1366,
        'VRES'       : 768,
        'H_POL'      :   1,  # positive polarity
        'H_BLANK'    : 134,
        'H_FRONT'    :  14,
        'H_SYNC'     :  56,
        'V_POL'      :   1,  # positive polarity
        'V_BLANK'    :  32,
        'V_FRONT'    :   1,
        'V_SYNC'     :   3
    },
    {  # mode 3 = 672x384
        'PIX_TIME' :    40.00,  # 25 MHz
        'HRES'       : 672,
        'VRES'       : 384,
        'H_POL'      :   1,  # positive polarity
        'H_BLANK'    : 128,
        'H_FRONT'    :  16,
        'H_SYNC'     :  64,
        'V_POL'      :   1,  # positive polarity
        'V_BLANK'    : 137,
        'V_FRONT'    :  10,
        'V_SYNC'     :   2
    },
    {  # mode 4 = 1280x720
        'PIX_TIME' :    13.47,  # 74.25 MHz
        'HRES'       :1280,
        'VRES'       : 720,
        'H_POL'      :   1,  # positive polarity
        'H_BLANK'    : 370,
        'H_FRONT'    : 110,
        'H_SYNC'     :  40,
        'V_POL'      :   1,  # positive polarity
        'V_BLANK'    :  30,
        'V_FRONT'    :   5,
        'V_SYNC'     :   5
    }
]
