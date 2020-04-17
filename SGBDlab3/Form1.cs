using System;
using System.Collections.Generic;
using System.Data;
using System.Windows.Forms;
using System.Data.SqlClient;


namespace SGBDlab3
{

    public partial class Form1 : Form
    {
        SqlConnection connection = new SqlConnection(@"Data Source=DESKTOP-A1S24IB\SQLEXPRESS;Initial Catalog=movie;Integrated Security=True");
        //SqlConnection connection = new SqlConnection("Data Source=DESKTOP-A1S24IB\\SQLEXPRESS;Initial Catalog=...;Integrated Security=True");
        SqlDataAdapter adapter = new SqlDataAdapter();
        SqlDataAdapter adapter2 = new SqlDataAdapter();
        SqlDataAdapter adapter3 = new SqlDataAdapter();
        SqlDataAdapter adapter4 = new SqlDataAdapter();
        DataSet data = new DataSet();
        DataSet data2 = new DataSet();
        DataSet data3 = new DataSet();
        DataSet data4 = new DataSet();

        public Form1()
        {
            InitializeComponent();
            dataGridViewParent.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dataGridViewChild.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dataGridView1.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        }

        private void updateThis()
        {
            adapter.SelectCommand = new SqlCommand("SELECT * FROM Filme", connection);
            data.Clear();
            adapter.Fill(data);
            dataGridViewParent.DataSource = data.Tables[0];//luam tabelul returnat de query


            adapter2.SelectCommand = new SqlCommand("SELECT * FROM Critica", connection);
            data2.Clear();
            adapter2.Fill(data2);
            dataGridViewChild.DataSource = data2.Tables[0];//luam tabelul returnat de query


            adapter3.SelectCommand = new SqlCommand("SELECT * FROM Genuri", connection);
            data3.Clear();
            adapter3.Fill(data3);
            dataGridView1.DataSource = data3.Tables[0];//luam tabelul returnat de query
        }

        private void button1_Click(object sender, EventArgs e) // - să se afişeze toate înregistrările tabelei părinte;
        {
            updateThis();

            adapter4.SelectCommand = new SqlCommand("SELECT * FROM Logger", connection);
            data4.Clear();
            adapter4.Fill(data4);
            dataGridView2.DataSource = data4.Tables[0];//luam tabelul returnat de query
        }

        private void button2_Click(object sender, EventArgs e)
        {

            SqlCommand cmd = new SqlCommand("usp_lab3_sgbd_rollback", connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@titlu", textBox1.Text);
            cmd.Parameters.AddWithValue("@gen", textBox2.Text);
            connection.Open();
            try
            {
                int rowAffected2 = cmd.ExecuteNonQuery();
                MessageBox.Show(rowAffected2 + " affected rows by the procedure");
            }
            catch(Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
            connection.Close();

            adapter4.SelectCommand = new SqlCommand("SELECT * FROM Logger", connection);
            data4.Clear();
            adapter4.Fill(data4);
            dataGridView2.DataSource = data4.Tables[0];//luam tabelul returnat de query

            updateThis();
        }

        private void button3_Click(object sender, EventArgs e)
        {
            SqlCommand cmd = new SqlCommand("usp_lab3_sgbd_checkpoint", connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@titlu", textBox1.Text);
            cmd.Parameters.AddWithValue("@gen", textBox2.Text);
            connection.Open();
            try
            {
                int rowAffected2 = cmd.ExecuteNonQuery();
                MessageBox.Show(rowAffected2 + " affected rows by the procedure");
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);

            }
            connection.Close();

            adapter4.SelectCommand = new SqlCommand("SELECT * FROM Logger", connection);
            data4.Clear();
            adapter4.Fill(data4);
            dataGridView2.DataSource = data4.Tables[0];//luam tabelul returnat de query

            updateThis();
        }
    }
}
