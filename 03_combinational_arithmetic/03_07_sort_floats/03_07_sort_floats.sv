//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Промежуточные массивы между стадиями сети сортировки
    logic [0:2][FLEN - 1:0] stage1;
    logic [0:2][FLEN - 1:0] stage2;

    // Результаты сравнения и ошибки от компараторов
    logic c01_stage0, c12_stage1, c01_stage2;
    logic err01_stage0, err12_stage1, err01_stage2;

    // 1-й компаратор: упорядочиваем unsorted[0] и unsorted[1]
    f_less_or_equal cmp01_stage0 (
        .a   ( unsorted[0]   ),
        .b   ( unsorted[1]   ),
        .res ( c01_stage0    ),
        .err ( err01_stage0  )
    );

    // 2-й компаратор: далее упорядочиваем элементы 1 и 2 после первой стадии
    f_less_or_equal cmp12_stage1 (
        .a   ( stage1[1]     ),
        .b   ( stage1[2]     ),
        .res ( c12_stage1    ),
        .err ( err12_stage1  )
    );

    // 3-й компаратор: финальное упорядочивание элементов 0 и 1
    f_less_or_equal cmp01_stage2 (
        .a   ( stage2[0]     ),
        .b   ( stage2[1]     ),
        .res ( c01_stage2    ),
        .err ( err01_stage2  )
    );

    // Комбинационная логика перестановки элементов
    always_comb begin
        // -------------------
        // Стадия 1: (0,1)
        // -------------------
        if (c01_stage0) begin
            stage1[0] = unsorted[0];
            stage1[1] = unsorted[1];
        end
        else begin
            stage1[0] = unsorted[1];
            stage1[1] = unsorted[0];
        end
        stage1[2] = unsorted[2];

        // -------------------
        // Стадия 2: (1,2)
        // -------------------
        if (c12_stage1) begin
            stage2[1] = stage1[1];
            stage2[2] = stage1[2];
        end
        else begin
            stage2[1] = stage1[2];
            stage2[2] = stage1[1];
        end
        stage2[0] = stage1[0];

        // -------------------
        // Стадия 3: (0,1)
        // -------------------
        if (c01_stage2) begin
            sorted[0] = stage2[0];
            sorted[1] = stage2[1];
        end
        else begin
            sorted[0] = stage2[1];
            sorted[1] = stage2[0];
        end
        sorted[2] = stage2[2];
    end

    // Любая ошибка из трёх компараторов поднимает общий флаг err
    assign err = err01_stage0 | err12_stage1 | err01_stage2;

endmodule

