#include <iostream>
#include <omp.h>
#include <fstream>
#include <cmath>

using namespace std;

int result[3];
size_t width, height;
int count_shades = 255;
long long count_char = 0;
char *buffer;
int start_index;

void otsu_with_parallel(int number_thread) {
    if (number_thread > 0) {
        omp_set_num_threads(number_thread);
    }

    size_t shades[count_shades];
    for (int i = 0; i < 256; i++) {
        shades[i] = 0;
    }

#pragma omp parallel
    {
        size_t shades_local[256];
        for (int i = 0; i < 256; i++) {
            shades_local[i] = 0;
        }

#pragma omp for nowait
        for (size_t i = 0; i < count_char; i++) {
            shades_local[(unsigned char) int(buffer[i + start_index])]++;
        }

#pragma omp critical
        {
            for (int i = 0; i < 256; i++) {
                shades[i] += shades_local[i];
            }
        }
    }


    double max_sigma = 0;
    int res[3];
    size_t prefix_shades[256];
    size_t prefix_mu[256];
    prefix_shades[0] = shades[0];
    prefix_mu[0] = 0;
    for (int i = 1; i < 256; i++) {
        prefix_shades[i] = shades[i] + prefix_shades[i - 1];
        prefix_mu[i] = prefix_mu[i - 1] + i * shades[i];
    }

#pragma omp parallel
    {
        double max_sigma_local = max_sigma;
        int res_local[3];

        for (int f_1 = 0; f_1 < count_shades - 2; f_1++) {
            for (int f_2 = f_1 + 1; f_2 < count_shades - 1; f_2++) {
#pragma omp for nowait
                for (int f_3 = f_2 + 1; f_3 < count_shades; f_3++) {
                    double q_double[4];
                    double m_double[4];

                    q_double[0] = (double) prefix_shades[f_1];
                    q_double[1] = (double) (prefix_shades[f_2] - prefix_shades[f_1]);
                    q_double[2] = (double) (prefix_shades[f_3] - prefix_shades[f_2]);
                    q_double[3] = (double) (prefix_shades[255] - prefix_shades[f_3]);

                    m_double[0] = (double) prefix_mu[f_1];
                    m_double[1] = (double) (prefix_mu[f_2] - prefix_mu[f_1]);
                    m_double[2] = (double) (prefix_mu[f_3] - prefix_mu[f_2]);
                    m_double[3] = (double) (prefix_mu[255] - prefix_mu[f_3]);

                    // m[i] = sum(i * P(i)) / count_char / q[i]
                    // sigma = sum(m[i]^2) * q[i]
                    // => sigma = sum(i * P(i) / count_char)^2 / q[i]
                    // q[i] = sum(P(i)) / count_char
                    // => sigma = sum(i * P(i))^2 / sum(P(i)) / count_char
                    double sigma = 0;
                    for (int i = 0; i < 4; i++) {
                        if (q_double[i] == 0) {
                            break;
                        }
                        sigma += m_double[i] * m_double[i] / q_double[i] / (double) count_char;
                    }
                    if (sigma > max_sigma_local) {
                        max_sigma_local = sigma;
                        res_local[0] = f_1;
                        res_local[1] = f_2;
                        res_local[2] = f_3;
                    }
                }
            }
        }
#pragma omp critical
        {
            if (max_sigma_local > max_sigma) {
                max_sigma = max_sigma_local;
                for (int i = 0; i < 3; i++) {
                    res[i] = res_local[i];
                }
            }
        }
    }

    result[0] = res[0];
    result[1] = res[1];
    result[2] = res[2];


#pragma omp parallel
    {
#pragma omp for
        for (size_t i = 0; i < count_char; i++) {
            int now = (unsigned char) buffer[i + start_index];
            if (now <= result[0]) {
                buffer[i + start_index] = (char) 0;
            } else if (now <= result[1]) {
                buffer[i + start_index] = (char) 84;
            } else if (now <= result[2]) {
                buffer[i + start_index]= (char) 170;
            } else {
                buffer[i + start_index] = (char) 255;
            }
        }
    }
}

void otsu_without_parallel() {
    int shades[256];
    for (int i = 0; i < 256; i++) {
        shades[i] = 0;
    }
    for (int i = 0; i < count_char; i++) {
        shades[(unsigned char) int(buffer[i + start_index])]++;
    }

    double max_sigma = 0;
    int res[3];
    int prefix_shades[256];
    int prefix_mu[256];
    prefix_shades[0] = shades[0];
    prefix_mu[0] = 0;
    for (int i = 1; i < 256; i++) {
        prefix_shades[i] = shades[i] + prefix_shades[i - 1];
        prefix_mu[i] = prefix_mu[i - 1] + i * shades[i];
    }
    double max_sigma_local = max_sigma;
    int res_local[3];

    for (int f_1 = 0; f_1 < count_shades - 2; f_1++) {
        for (int f_2 = f_1 + 1; f_2 < count_shades - 1; f_2++) {
            for (int f_3 = f_2 + 1; f_3 < count_shades; f_3++) {
                double q_double[4];
                double m_double[4];

                q_double[0] = (double) prefix_shades[f_1];
                q_double[1] = (double) (prefix_shades[f_2] - prefix_shades[f_1]);
                q_double[2] = (double) (prefix_shades[f_3] - prefix_shades[f_2]);
                q_double[3] = (double) (prefix_shades[255] - prefix_shades[f_3]);

                m_double[0] = (double) prefix_mu[f_1];
                m_double[1] = (double) (prefix_mu[f_2] - prefix_mu[f_1]);
                m_double[2] = (double) (prefix_mu[f_3] - prefix_mu[f_2]);
                m_double[3] = (double) (prefix_mu[255] - prefix_mu[f_3]);

                // m[i] = sum(i * P(i)) / count_char / q[i]
                // sigma = sum(m[i]^2) * q[i]
                // => sigma = sum(i * P(i) / count_char)^2 / q[i]
                // q[i] = sum(P(i)) / count_char
                // => sigma = sum(i * P(i))^2 / sum(P(i)) / count_char
                double sigma = 0;
                for (int i = 0; i < 4; i++) {
                    if (q_double[i] == 0) {
                        break;
                    }
                    sigma += m_double[i] * m_double[i] / q_double[i] / (double) count_char;
                }
                if (sigma > max_sigma_local) {
                    max_sigma_local = sigma;
                    res_local[0] = f_1;
                    res_local[1] = f_2;
                    res_local[2] = f_3;
                }
            }
        }
        if (max_sigma_local > max_sigma) {
            max_sigma = max_sigma_local;
            for (int i = 0; i < 3; i++) {
                res[i] = res_local[i];
            }
        }
    }

    result[0] = res[0];
    result[1] = res[1];
    result[2] = res[2];

    for (size_t i = 0; i < count_char; i++) {
        int now = (unsigned char) buffer[i + start_index];
        if (now <= result[0]) {
            buffer[i + start_index] = (char) 0;
        } else if (now <= result[1]) {
            buffer[i + start_index] = (char) 84;
        } else if (now <= result[2]) {
            buffer[i + start_index] = (char) 170;
        } else {
            buffer[i + start_index] = (char) 255;
        }
    }
}

void threshold_filtering_otsu_method(int count_thread) {
    if (count_thread >= 0) {
        otsu_with_parallel(count_thread);
    } else {
        otsu_without_parallel();
    }
}



int read(string name_in) {
    ifstream fin(name_in, ifstream::binary);

    if (!fin.is_open()) {
        cout << "Error, not open input file" << endl;
        return -1;
    } else {
        fin.seekg(0, fin.end);
        size_t length = fin.tellg();
        fin.seekg(0, fin.beg);

        buffer = new char[length];
        fin.read(buffer, length);

        string test = "";
        for (int i = 0; i < 3; i++) {
            test += buffer[i];
        }
        start_index = 3;
        if (test != "P5\n") {
            cout << "Error, file format is incorrect";
            return -1;
        }
        try {
            test = "";
            while (!isspace(buffer[start_index])) {
                test += buffer[start_index];
                start_index++;
            }
            start_index++; // ' '
            width = atoi(test.c_str());
            test = "";
            while (buffer[start_index] != '\n') {
                test += buffer[start_index];
                start_index++;
            }
            height = atoi(test.c_str());
            start_index++; // \n
            test = "";
            for (int i = 0; i < 4; i++) {
                test += buffer[start_index];
                start_index++;
            }

            if (test != "255\n") {
                cout << "Error, file format is incorrect";
                return -1;
            }

            if (length - start_index != width * height) {
                cout << "Error, file format is incorrect";
                return -1;
            }
        } catch (exception ex) {
            cout << "Error, file format is incorrect";
            return -1;
        }

        count_char = length - start_index;
        fin.close();

    }
    return 0;
}


void write(string name_out) {
    ofstream fout(name_out);
    fout << "P5\n" << width << " " << height << "\n255\n";
    for (size_t i = 0; i < count_char; i++) {
        fout << buffer[i + start_index];
    }
    fout.close();
}


int main(int argc, char *argv[]) {
    if (argc != 4) {
        cout << "Error, expect 4 arg, actual " << argc;
        return 0;
    }
    int count_threads = atoi(argv[1]);
    string name_in = argv[2];
    string name_out = argv[3];

    if (read(name_in) != 0) {
        return 0;
    }

    double time_start = omp_get_wtime();

    threshold_filtering_otsu_method(count_threads);

    double time_count = omp_get_wtime() - time_start;
    printf("Time (%i thread(s)): %g ms\n", count_threads, time_count * 1000);

    for (int i = 0; i < 3; i++) {
        cout << result[i] << " ";
    }
    cout << "\n";

    write(name_out);
//    cout << "Successful\n";

    return 0;
}