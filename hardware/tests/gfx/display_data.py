# Isle.Computer - Display Controller Test Data
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Display timing data for display tests."""

DT = [
    {  # mode 0 = 640x400 CVT
        'PIX_TIME' :    50,  # 20 MHz
        'HRES'       : 640,
        'VRES'       : 400,
        'H_POL'      :   0,  # negative polarity
        'H_BLANK'    : 160,
        'H_FRONT'    :  16,
        'H_SYNC'     :  64,
        'V_POL'      :   1,  # positive polarity
        'V_BLANK'    :  17,
        'V_FRONT'    :   3,
        'V_SYNC'     :   6
    },
    {  # mode 1 = 1280x800 CVT-RT
        'PIX_TIME' :    14.08, # 71 MHz
        'HRES'       :1280,
        'VRES'       : 800,
        'H_POL'      :   1,  # positive polarity
        'H_BLANK'    : 320,
        'H_FRONT'    :  24,
        'H_SYNC'     : 136,
        'V_POL'      :   0,  # negative polarity
        'V_BLANK'    :  38,
        'V_FRONT'    :   3,
        'V_SYNC'     :   6
    },
    {  # mode 2 = 1280x720 CEA-861
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
