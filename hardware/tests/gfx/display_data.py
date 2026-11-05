# Isle.Computer - Display Controller Test Data
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Display timing data for display tests."""

DT = [
    {  # mode 0 = 640x360
        'PIX_TIME' :    50.0,  # 20.0 MHz
        'HRES'       : 640,
        'VRES'       : 360,
        'H_POL'      :   1,  # positive polarity
        'H_BLANK'    : 248,
        'H_FRONT'    :  32,
        'H_SYNC'     :  96,
        'V_POL'      :   1,  # positive polarity
        'V_BLANK'    :  15,
        'V_FRONT'    :   3,
        'V_SYNC'     :   5
    },
    {  # mode 1 = 1280x720
        'PIX_TIME' :    13.468,  # 74.25 MHz
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
