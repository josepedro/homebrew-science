class SuperluDist < Formula
  desc "A general purpose library for the direct solution of large, sparse, nonsymmetric systems of linear equations on high performance machines."
  homepage "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/"
  url "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_dist_4.1.tar.gz"
  sha256 "8afb48036e9b3020d268d49d5a3711aaed2f65105747aa6a111ff8f64dcde93e"

  bottle do
    cellar :any
    revision 3
    sha256 "55eccd7c3e2e83e5b9d4ed64ac5929d0efb590a536dd59932e6422789e33e351" => :el_capitan
    sha256 "44f110d14c23c6d1cb2cc0b8d21e96f777c780a641a2164a838adc57c383af00" => :yosemite
    sha256 "72c0a1f964113d286ca161f9e2dec1d0d99d5007d5071dc38af5f7ef0b2bf397" => :mavericks
  end

  depends_on :fortran
  depends_on :mpi => [:cc, :f77]

  depends_on "parmetis"
  depends_on "openblas" => :optional

  # fix duplicate symbols [mc64dd_,mc64ed_,mc64fd_] when linking with superlu
  patch do
    url "https://bitbucket.org/petsc/pkg-superlu_dist/commits/2faf8669a2ba20250ffe2d8a1b63d4f8ef8c5b74/raw/"
    sha256 "67e2966e1a9b4e3471374d1e720946c2ef34403d00e796767b51718e4d50604f"
  end

  def install
    # prevent linking errors on linuxbrew:
    ENV.deparallelize
    rm "#{buildpath}/make.inc"
    blaslib = ((build.with? "openblas") ? "-L#{Formula["openblas"].opt_lib} -lopenblas" : "-framework Accelerate")
    (buildpath / "make.inc").write <<-EOS.undent
      PLAT         = _mac_x
      DSuperLUroot = #{buildpath}
      DSUPERLULIB  = $(DSuperLUroot)/lib/libsuperlu_dist.a
      BLASDEF      = -DUSE_VENDOR_BLAS
      BLASLIB      = #{blaslib}
      METISLIB     = -L#{Formula["metis"].opt_lib} -lmetis
      PARMETISLIB  = -L#{Formula["parmetis"].opt_lib} -lparmetis
      FLIBS        =
      LIBS         = $(DSUPERLULIB) $(BLASLIB) $(PARMETISLIB) $(METISLIB)
      ARCH         = ar
      ARCHFLAGS    = cr
      RANLIB       = true
      CC           = #{ENV["MPICC"]}
      CFLAGS       = -fPIC -O2 -I#{Formula["parmetis"].opt_include} -I#{Formula["metis"].opt_include}
      NOOPTS       = -fPIC
      FORTRAN      = #{ENV["MPIF77"]}
      F90FLAGS     = -O2
      LOADER       = #{ENV["MPIF77"]}
      LOADOPTS     =
      CDEFS        = -DAdd_
    EOS

    system "make", "lib"
    cd "EXAMPLE" do
      system "make"
    end
    prefix.install "make.inc" # Record make.inc used
    lib.install Dir["lib/*"]
    (include / "superlu_dist").install Dir["SRC/*.h"]
    doc.install Dir["Doc/*"]
    (share / "superlu_dist").install "EXAMPLE"
  end

  test do
    cd (share / "superlu_dist/EXAMPLE") do
      system "mpirun", "-np", "4", "./pddrive", "-r", "2", "-c", "2", "g20.rua"
      system "mpirun", "-np", "10", "./pddrive4", "g20.rua"
      system "mpirun", "-np", "4", "./pzdrive", "-r", "2", "-c", "2", "cg20.cua"
      system "mpirun", "-np", "10", "./pzdrive4", "cg20.cua"
    end
  end
end
